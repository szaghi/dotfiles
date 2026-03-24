#!/bin/bash
sudo dpkg --set-selections <  $1
sudo apt-get dselect-upgrade
