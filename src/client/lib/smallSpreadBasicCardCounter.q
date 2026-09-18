system"l src/client/lib/playerCore.q";

// recommended value that tells the user what to bet. uses theCount function to determine this value
// use generic values to start - use percentages after a while - beating the double deck game part 2 - blackjackinfo.com
getBet:{
  if[theCount<2;:10];
  if[(theCount>=2)&(theCount<3);:15];
  if[(theCount>=3)&(theCount<4);:20];
  if[(theCount>=4)&(theCount<5);:25];
  :30
  };
