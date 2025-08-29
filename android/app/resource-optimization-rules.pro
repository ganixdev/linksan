# Resource optimization configuration for LinkSan
# This file helps identify and remove unused resources

# Keep essential resources and allow aggressive shrinking
-allowaccessmodification
-adaptresourcefilenames
-adaptresourcefilecontents

# Aggressive resource shrinking
-dontpreverify
-repackageclasses

# Remove unused Android resources
-ignorewarnings

# Keep only used resources from libraries
-keep class **.R$* {
    public static final int *;
}

# Remove unused assets (if any)
# Note: Flutter assets are handled separately
