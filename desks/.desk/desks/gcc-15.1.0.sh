# gcc-15.1.0.sh
#
# Description: gcc 15.1.0 environment
#
GCC=/opt/gcc/bin/15.1.0
PATH=$GCC/bin:$PATH
LD_LIBRARY_PATH=$GCC/lib/openmpi:$GCC/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$GCC/lib/openmpi:$GCC/lib:$LD_RUN_PATH
MANPATH=$GCC/share/man:$MANPATH
export PATH LD_LIBRARY_PATH LD_RUN_PATH MANPATH

if [ -d "/opt/gcc/bin/15.1.0" ]; then
    export GCC_HOME="/opt/gcc/bin/15.1.0"
    export PATH="$GCC_HOME/bin:$PATH"

    # Librerie dinamiche
    if [ -d "$GCC_HOME/lib64" ]; then
        export LD_LIBRARY_PATH="$GCC_HOME/lib64:${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH}"
    fi
    if [ -d "$GCC_HOME/lib" ]; then
        export LD_LIBRARY_PATH="$GCC_HOME/lib:${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH}"
    fi

    # Documentazione
    if [ -d "$GCC_HOME/share/man" ]; then
        export MANPATH="$GCC_HOME/share/man:${MANPATH:+$MANPATH}"
    fi
    if [ -d "$GCC_HOME/share/info" ]; then
        export INFOPATH="$GCC_HOME/share/info:${INFOPATH:+$INFOPATH}"
    fi

    # Include paths per pkg-config (se necessario)
    if [ -d "$GCC_HOME/lib/pkgconfig" ]; then
        export PKG_CONFIG_PATH="$GCC_HOME/lib/pkgconfig:${PKG_CONFIG_PATH:+$PKG_CONFIG_PATH}"
    fi
    if [ -d "$GCC_HOME/lib64/pkgconfig" ]; then
        export PKG_CONFIG_PATH="$GCC_HOME/lib64/pkgconfig:${PKG_CONFIG_PATH:+$PKG_CONFIG_PATH}"
    fi
fi
