echo "Installing scenario..."
while [ ! -f /tmp/finished ]; do sleep 1 && echo -n "."; done
echo DONE

wash completions -d $HOME/.wash bash

source /root/.bashrc
direnv allow
