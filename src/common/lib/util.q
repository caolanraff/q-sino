.util.script:{.z.f};                                                                               / the process's entry script, wrapped so tests can mock it
.util.run:{[f;init]if[not[null s]&f~last` vs hsym s:.util.script[];init[]]};                       / [file;init] call init if file is the entry script, e.g. .util.run[`blackjack.q;`.bjk.init]
