#!/bin/bash

set -e

echo "[1/5] Install gpiod..."
apt update -y
apt install -y gpiod

echo "[2/5] Create script hgled..."

cat > /usr/local/bin/hgled.sh << 'EOF'
#!/bin/bash

GREEN_CHIP="gpiochip1"
GREEN=24

RED_CHIP="gpiochip0"
RED=6

stop_all() {
    killall gpioset 2>/dev/null
}

while true; do
    if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo "[✓] Internet ON → GREEN flashing slowly"

        stop_all

        # red off
        gpioset -z -c $RED_CHIP -l $RED=1

        # green flashing slowly
        gpioset -c $GREEN_CHIP -l -t 1000,1000 $GREEN=0 &

    else
        echo "[✗] Internet OFF → RED fast flashing"

        stop_all

        # green off
        gpioset -z -c $GREEN_CHIP -l $GREEN=1

        # red fast flashing
        gpioset -c $RED_CHIP -l -t 300,300 $RED=0 &
    fi

    sleep 5
done
EOF

chmod +x /usr/local/bin/hgled.sh

echo "[3/5] Create service systemd..."

cat > /etc/systemd/system/hgled.service << 'EOF'
[Unit]
Description=HG680P Internet LED Indicator
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/hgled.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "[4/5] Enable service..."

systemctl daemon-reload
systemctl enable hgled
systemctl restart hgled

echo "[5/5] Done..!"

echo "====================================="
echo "✔ Internet LED is active"
echo "✔ Auto-start at boot"
echo "✔ No further settings required"
echo "====================================="
sleep 10
clear
