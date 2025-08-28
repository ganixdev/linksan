package com.ganixdev.linksan

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import org.json.JSONObject
import org.json.JSONArray
import java.io.InputStream

class ShareHandlerActivity : FlutterActivity() {
    private val CHANNEL = "com.ganixdev.linksan/url"
    private lateinit var flutterEngine: FlutterEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle the shared text
        val intent = intent
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (sharedText != null && isValidUrl(sharedText)) {
                // Process the URL silently and re-share
                processAndReshareUrl(sharedText)
            } else {
                // If not a valid URL, just finish
                finish()
            }
        } else {
            finish()
        }
    }

    private fun isValidUrl(text: String): Boolean {
        val trimmedText = text.trim()
        return trimmedText.startsWith("http://") || trimmedText.startsWith("https://")
    }

    private fun processAndReshareUrl(url: String) {
        try {
            val trimmedUrl = url.trim()
            println("Processing URL: $trimmedUrl")

            // Load rules and sanitize URL
            val (sanitizedUrl, removedCount) = sanitizeUrl(trimmedUrl)

            println("About to share sanitized URL: $sanitizedUrl")

            // Show success toast with tracker count
            val toastMessage = if (removedCount > 0) {
                "$removedCount tracker${if (removedCount == 1) "" else "s"} removed!"
            } else {
                "No trackers found - URL is clean!"
            }
            Toast.makeText(this, toastMessage, Toast.LENGTH_SHORT).show()

            // Create new share intent with sanitized URL
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, sanitizedUrl)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            // Start the share intent
            startActivity(Intent.createChooser(shareIntent, "Share sanitized URL"))

            // Delay finishing to allow toast to be visible
            Handler(Looper.getMainLooper()).postDelayed({
                finish()
            }, 1000) // 1.5 seconds delay

        } catch (e: Exception) {
            e.printStackTrace()
            println("Error processing URL, falling back to original: ${e.message}")

            // Show error toast
            Toast.makeText(this, "Error sanitizing URL, sharing original", Toast.LENGTH_SHORT).show()

            // Fallback: share original URL
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, url.trim())
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(Intent.createChooser(shareIntent, "Share URL"))

            // Delay finishing to allow toast to be visible
            Handler(Looper.getMainLooper()).postDelayed({
                finish()
            }, 1000) // 1.5 seconds delay
        }

        // Note: finish() is now called with delay in both try and catch blocks above
    }

    private fun sanitizeUrl(url: String): Pair<String, Int> {
        return try {
            // Load rules from assets
            val rulesJson = loadRulesFromAssets()
            val trackingParams = getTrackingParameters(rulesJson)
            val domainRules = getDomainRules(rulesJson)

            // Parse the URL
            val uri = Uri.parse(url)
            val domain = extractDomain(uri.host ?: "")

            println("Original URL: $url")
            println("Extracted domain: $domain")

            // Handle Google redirect URLs
            var actualUrl = url
            var totalRemovedCount = 0

            if (domain == "google.com" && uri.path == "/url" && uri.getQueryParameter("url") != null) {
                println("Google redirect detected!")
                val encodedUrl = uri.getQueryParameter("url")
                if (encodedUrl != null) {
                    try {
                        actualUrl = Uri.decode(encodedUrl)
                        println("Decoded destination URL: $actualUrl")
                        val actualUri = Uri.parse(actualUrl)
                        val destinationDomain = extractDomain(actualUri.host ?: "")
                        println("Destination domain: $destinationDomain")

                        // First, remove trackers from the Google redirect URL itself
                        val googleQueryParams = uri.queryParameterNames
                        val googleBuilder = uri.buildUpon()
                        googleBuilder.clearQuery()

                        if (domainRules.has(domain)) {
                            val domainRule = domainRules.getJSONObject(domain)
                            val keepParams = getStringArray(domainRule.getJSONArray("keep"))
                            val removeParams = getStringArray(domainRule.getJSONArray("remove"))

                            // Remove Google-specific parameters
                            for (param in googleQueryParams) {
                                val shouldKeep = keepParams.contains(param) ||
                                               (!trackingParams.contains(param) && !removeParams.contains(param))
                                if (shouldKeep) {
                                    val value = uri.getQueryParameter(param)
                                    if (value != null) {
                                        googleBuilder.appendQueryParameter(param, value)
                                    }
                                } else {
                                    totalRemovedCount++
                                    println("Removed Google parameter: $param")
                                }
                            }
                        }

                        // Now process the destination URL
                        val destinationQueryParams = actualUri.queryParameterNames
                        val destinationBuilder = actualUri.buildUpon()
                        destinationBuilder.clearQuery()

                        if (domainRules.has(destinationDomain)) {
                            val domainRule = domainRules.getJSONObject(destinationDomain)
                            val keepParams = getStringArray(domainRule.getJSONArray("keep"))
                            val removeParams = getStringArray(domainRule.getJSONArray("remove"))

                            // Remove domain-specific parameters from destination
                            for (param in destinationQueryParams) {
                                val shouldKeep = keepParams.contains(param) ||
                                               (!trackingParams.contains(param) && !removeParams.contains(param))
                                if (shouldKeep) {
                                    val value = actualUri.getQueryParameter(param)
                                    if (value != null) {
                                        destinationBuilder.appendQueryParameter(param, value)
                                    }
                                } else {
                                    totalRemovedCount++
                                    println("Removed destination parameter: $param")
                                }
                            }
                        } else {
                            // No domain-specific rules for destination, remove all tracking parameters
                            for (param in destinationQueryParams) {
                                if (!trackingParams.contains(param)) {
                                    val value = actualUri.getQueryParameter(param)
                                    if (value != null) {
                                        destinationBuilder.appendQueryParameter(param, value)
                                    }
                                } else {
                                    totalRemovedCount++
                                    println("Removed destination tracking parameter: $param")
                                }
                            }
                        }

                        val result = destinationBuilder.build().toString()
                        println("Final sanitized URL: $result")
                        println("Total parameters removed: $totalRemovedCount")
                        return Pair(result, totalRemovedCount)

                    } catch (e: Exception) {
                        println("Error decoding Google redirect URL: ${e.message}")
                        actualUrl = url
                    }
                }
            }

            // Continue with normal processing for non-Google URLs
            val processingUri = Uri.parse(actualUrl)

            // Get current query parameters
            val queryParams = processingUri.queryParameterNames
            var removedCount = 0

            // Apply domain-specific rules if they exist
            val builder = processingUri.buildUpon()
            builder.clearQuery()

            if (domainRules.has(domain)) {
                val domainRule = domainRules.getJSONObject(domain)
                val keepParams = getStringArray(domainRule.getJSONArray("keep"))
                val removeParams = getStringArray(domainRule.getJSONArray("remove"))

                println("Applying domain-specific rules for $domain")
                println("Keep params: $keepParams")
                println("Remove params: $removeParams")

                // Add back only non-tracking parameters and keep parameters
                for (param in queryParams) {
                    val shouldKeep = keepParams.contains(param) ||
                                   (!trackingParams.contains(param) && !removeParams.contains(param))
                    if (shouldKeep) {
                        val value = processingUri.getQueryParameter(param)
                        if (value != null) {
                            builder.appendQueryParameter(param, value)
                        }
                    } else {
                        removedCount++
                        println("Removed parameter: $param")
                    }
                }
            } else {
                println("No domain-specific rules for $domain, using general tracking removal")
                // No domain-specific rules, remove all tracking parameters
                for (param in queryParams) {
                    if (!trackingParams.contains(param)) {
                        val value = processingUri.getQueryParameter(param)
                        if (value != null) {
                            builder.appendQueryParameter(param, value)
                        }
                    } else {
                        removedCount++
                        println("Removed tracking parameter: $param")
                    }
                }
            }

            val result = builder.build().toString()
            println("Sanitized URL: $result")
            println("Total parameters removed: ${totalRemovedCount + removedCount}")
            Pair(result, totalRemovedCount + removedCount)
        } catch (e: Exception) {
            e.printStackTrace()
            println("Error sanitizing URL: ${e.message}")
            Pair(url, 0) // Return original URL with 0 removed count if parsing fails
        }
    }

    private fun loadRulesFromAssets(): JSONObject {
        val inputStream: InputStream = assets.open("flutter_assets/assets/rules.json")
        val jsonString = inputStream.bufferedReader().use { it.readText() }
        return JSONObject(jsonString)
    }

    private fun getTrackingParameters(rulesJson: JSONObject): List<String> {
        val trackingArray = rulesJson.getJSONArray("tracking_parameters")
        return getStringArray(trackingArray)
    }

    private fun getDomainRules(rulesJson: JSONObject): JSONObject {
        return rulesJson.getJSONObject("domain_specific_rules")
    }

    private fun getStringArray(jsonArray: JSONArray): List<String> {
        val list = mutableListOf<String>()
        for (i in 0 until jsonArray.length()) {
            list.add(jsonArray.getString(i))
        }
        return list
    }

    private fun extractDomain(host: String): String {
        return host.removePrefix("www.")
    }
}
