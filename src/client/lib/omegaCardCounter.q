system"l src/client/lib/strategy.q";

setCountDict[`omega];

// reccommended value that tells the user what to bet. uses theCount function to determine this value
// use generic values to start - use percentages after a while - beating the double deck game part 2 - blackjackinfo.com
getBet:{
  if[theCount<2;:10];
  if[(theCount>=2)&(theCount<3);:25];
  if[(theCount>=3)&(theCount<4);:40];
  if[(theCount>=4)&(theCount<5);:60];
  :80
  };
