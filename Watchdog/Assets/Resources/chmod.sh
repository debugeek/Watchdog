#!/bin/sh

cd `dirname "${BASH_SOURCE[0]}"`

sudo chown root:admin wdctl
sudo chmod +s wdctl

echo "chmod done"
