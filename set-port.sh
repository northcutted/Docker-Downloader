
#!/bin/bash
echo "Setting Peer Port"
sed -i "/\"peer-port\"/c\    \"peer-port\": $(cat /config/forwarded_port)," /config/settings.json
echo "Peer Port Set to $(cat /config/forwarded_port)"
