whatis("AMD ROCm / AOCC 5.1.0")

help([[
AMD SDK 5.1.0 — installed at /opt/amd/rocm-afar-6711-drop-5.1.0
]])

local root = "/opt/amd/rocm-afar-6711-drop-5.1.0"

family("compiler")

if not isDir(root) then
  LmodError("AMD SDK 5.1.0 not found at " .. root)
end

prepend_path("PATH",            pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("MANPATH",         pathJoin(root, "share/man"))
