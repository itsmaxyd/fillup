#!/bin/bash
set -e

# Setup variables
KEYSTORE_DIR="app"
KEYSTORE_NAME="upload-keystore.jks"
KEYSTORE_PATH="$KEYSTORE_DIR/$KEYSTORE_NAME"
PROPERTIES_FILE="key.properties"
ALIAS="upload"
# Generate a random password or use a fixed one? 
# Using a fixed one for simplicity in this generated script, user can change it.
PASS="fuelupReleaseKey" 

echo "Generating upload keystore at $KEYSTORE_PATH..."

# Ensure directory exists
mkdir -p "$KEYSTORE_DIR"

# Check if keystore already exists to avoid overwriting
if [ -f "$KEYSTORE_PATH" ]; then
    echo "Keystore already exists at $KEYSTORE_PATH. Skipping generation."
else
    keytool -genkey -v -keystore "$KEYSTORE_PATH" \
            -storetype JKS \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -alias "$ALIAS" \
            -dname "CN=FuelUp, OU=App, O=FuelUp, L=Unknown, S=Unknown, C=Unknown" \
            -storepass "$PASS" \
            -keypass "$PASS"
    echo "Keystore generated."
fi

echo "Creating $PROPERTIES_FILE..."
# We use > to overwrite or create
cat > "$PROPERTIES_FILE" <<EOF
storePassword=$PASS
keyPassword=$PASS
keyAlias=$ALIAS
storeFile=$KEYSTORE_NAME
EOF

echo "--------------------------------------------------------"
echo "Signing configuration completed!"
echo "Keystore: android/$KEYSTORE_PATH"
echo "Properties: android/$PROPERTIES_FILE"
echo "Password (for both): $PASS"
echo ""
echo "IMPORTANT: DO NOT COMMIT THE KEYSTORE OR PROPERTIES FILE TO GIT."
echo "--------------------------------------------------------"
