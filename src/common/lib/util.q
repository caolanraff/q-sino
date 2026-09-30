.util.script:{.z.f};
.util.run:{[f;init]if[not[null s]&f~last` vs hsym s:.util.script[];init[]]};                       / ` vs only splits a path once it's a file handle
