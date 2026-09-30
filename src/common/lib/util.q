.cmn.script:{.z.f};
.cmn.run:{[f;init]if[not[null s]&f~last` vs hsym s:.cmn.script[];init[]]};                         / ` vs only splits a path once it's a file handle
