# DU-FactoryCloner
### lua script to clone factories out
# If you found this code helpful, please considder throwing some credits my way in the Settlers MYDU server. My IGN is 'ChaosRifle'
[TableIO](https://github.com/LexLoki/tableIO) provided under MIT is NOT my work, and all credit for tableIO goes to its dev. These are the library files.

How it works:
the Factory Cloner Origin script uses the core to grab all id's and state of the factory.
the Destination script reads that data and pushes it to any industry unit linked, by ID. The ID's match on newly printed ships, so this will make destination block X match origin block Y


Optimal use to minimize work:
set up the destination script(s) to be connected to the Origin factory at all times, so the links are all complete on all future prints, saving all the linking. 
For factories that exceed the limit on progbord link count, use of multiple destination progboards is preferred.

what you need:
- x2+ progblocks
- x1 Databank

to use:
- 1: grab the Origin script for a progblock paste the lua in
- 3: link the Origin progblock to the Core
- 4: link the Origin progblock to a Databank
- 5: name the core link 'core'
- 6: name the databank link 'DB'
- 7: run the origin progboard

- 8: grab the Destination script for a new, different, progblock paste the lua in
- 9: link the Destination progblock to the same Databank as step 4
- 10: name the databank link 'DB'
- 11: link the Destination progbord to as many industry elements as you can. if you run out of links, use another prog board, or, after step 12, unlink and link to new elements.
- 12: run the Destination progboard
