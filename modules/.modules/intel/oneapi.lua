whatis("Intel oneAPI compilers")

help([[
Intel oneAPI — sourced from /opt/intel/oneapi/setvars.sh
Includes icx, icpx, ifx, MKL, TBB, and Intel MPI.
Sets CC=icx, CXX=icpx, FC=ifx.
Note: setvars.sh is sourced on load and cannot be cleanly reversed on
unload — run 'module purge' and open a fresh shell to fully reset.
]])

family("compiler")

local setvars = "/opt/intel/oneapi/setvars.sh"

if not isFile(setvars) then
  LmodError("Intel oneAPI setvars.sh not found at " .. setvars)
end

-- setvars.sh sets all paths itself; execute on load only
execute { cmd = "source " .. setvars .. " --force > /dev/null 2>&1", when = "load" }

setenv("CC",  "icx")
setenv("CXX", "icpx")
setenv("FC",  "ifx")
setenv("F77", "ifx")
setenv("F90", "ifx")
