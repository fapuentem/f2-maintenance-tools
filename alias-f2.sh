
# F2  alias
alias run-f2='sudo /bin/python3  /home/nvidia/projects/F2-App/main.py'
alias logs-f2='tail -f /home/nvidia/projects/F2-App/logs/app.log'
alias status-f2='ps ax | grep [F]2-App'
alias sn-som-f2='tr -d "\0" </sys/firmware/devicetree/base/serial-number; echo'
alias sn-board-f2="sudo i2ctransfer -f -y 1 w1@0x58 0x80 r16 \
  | sed 's/0x//g; s/[[:space:]]//g'; echo"
# Add tools folder at PATH
export PATH="$HOME/tools/f2-maintenance-tools:$PATH"
