#!/bin/bash

# Configuration
SERVICE_NAME="medlink-kiosk"
USER_NAME=$USER
# Default build path for RPi (ARM64)
# Adjust if using armhv7 or x64
EXE_PATH="$(pwd)/build/linux/arm64/release/bundle/medlink_kiosk"

if [ ! -f "$EXE_PATH" ]; then
    echo "Error: Executable not found at $EXE_PATH"
    echo "Please ensure you have built the app with 'flutter build linux --release' inside this directory."
    echo "If you are on 32-bit RPi, check build/linux/arm/..."
    exit 1
fi

echo "Installing $SERVICE_NAME service for user $USER_NAME..."

# Create Service File
EOF

# Create a wrapper script to handle X11 setup
WRAPPER_PATH="$(pwd)/kiosk_launcher.sh"
cat > $WRAPPER_PATH <<EOF
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/$USER_NAME/.Xauthority

# Disable Screen Saver / Power Management
xset s noblank -display :0
xset s off -display :0
xset -dpms -display :0
# Hide cursor if using unclutter
# unclutter -idle 0.1 -root &

# Launch App
$EXE_PATH
EOF

chmod +x $WRAPPER_PATH

# Create Service File
sudo bash -c "cat > /etc/systemd/system/$SERVICE_NAME.service" <<EOF
[Unit]
Description=MedixaLink Kiosk Flutter App
After=network-online.target graphical.target
Wants=network-online.target

[Service]
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$(pwd)
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/$USER_NAME/.Xauthority"
# Add /usr/bin to PATH just in case
Environment="PATH=/usr/bin:/usr/local/bin:/bin"

ExecStart=$WRAPPER_PATH
Restart=always
RestartSec=5s

[Install]
WantedBy=graphical.target
EOF

# Reload and Enable
echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling service to start on boot..."
sudo systemctl enable $SERVICE_NAME

echo "Starting service now..."
sudo systemctl restart $SERVICE_NAME

echo "Done! Service status:"
systemctl status $SERVICE_NAME --no-pager

echo ""
echo "-----------------------------------------------------"
echo "Useful Commands:"
echo "  Restart: sudo systemctl restart $SERVICE_NAME"
echo "  Stop:    sudo systemctl stop $SERVICE_NAME"
echo "  Logs:    journalctl -u $SERVICE_NAME -f"
echo "-----------------------------------------------------"
