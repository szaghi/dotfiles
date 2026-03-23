whatis("GCC 15.1.0 compiler toolchain")

help([[
GCC 15.1.0 — installed at /opt/gcc/bin/15.1.0
Sets CC=gcc, CXX=g++, FC=gfortran.
]])

local root = "/opt/gcc/bin/15.1.0"

family("compiler")  -- only one compiler active at a time

if not isDir(root) then
  LmodError("GCC 15.1.0 not found at " .. root)
end

prepend_path("PATH",             pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH",  pathJoin(root, "lib64"))
prepend_path("LD_LIBRARY_PATH",  pathJoin(root, "lib"))
prepend_path("LD_RUN_PATH",      pathJoin(root, "lib64"))
prepend_path("LD_RUN_PATH",      pathJoin(root, "lib"))
prepend_path("MANPATH",          pathJoin(root, "share/man"))
prepend_path("INFOPATH",         pathJoin(root, "share/info"))
prepend_path("PKG_CONFIG_PATH",  pathJoin(root, "lib/pkgconfig"))
prepend_path("PKG_CONFIG_PATH",  pathJoin(root, "lib64/pkgconfig"))

setenv("GCC_HOME", root)
setenv("CC",  "gcc")
setenv("CXX", "g++")
setenv("FC",  "gfortran")
setenv("F77", "gfortran")
setenv("F90", "gfortran")
