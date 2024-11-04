### Overview  <a name="overview"/>
The two scripts in this repository can be used to recursively generate a pedigree, given
tab-separated data of the form `individual parent1 parent2`; and also to determine what
other lines in the data have a specified line in their pedigree, and any aliases and comments
regarding the specified line.

### Main program for recursively calculating pedigrees from parentage data:
```
  Usage:  parentage.pl -parents FILE [-options]

  Given a file of individuals and parents, recursively determine the pedigree
  (the parentage going back as many generations as possible) for an individual.
  Can be calculated for a single indicated individual or for all in the parents file.

  The parents file should be structured like this.
  The individual (progeny) is on the left, and the parents are on the right
    indID  parent1  parent2
    A      B        C
    D      B        C
    E      B        F

  Required:
    -parents  File listing the individuals and parents

  Options:
    -query    ID of an individual for which to calculate parentage.
              If not provided, report parentage for all individuals.
    -outfile  Print to indicated filename; otherwise to STDOUT. 
              If -outfile "QUERY" is indicated, the query name will be used (with spaces replaced by underscores).
    -outdir   If outfile is specified, write files to this directory. Default "."
    -format   Output format. Options: string, table. Either or both (string,table) can be specified. [string]
    -last_only     For string format, print only the last pedigree string; otherwise, print one for each data line.
    -max_ped_size  The maximum number of individuals in the pedigree to report.
                        When this number is reached, the pedigree of that size will be reported,
                        even if other parents may be found in the input data.
    -verbose  Report some intermediate information.
    -help     This message.
```

### Wrapper program that generates a report including synonyms, comments, and lines with the query individual in their pedigree:
```
  Usage:  parentage_report.pl -parents FILE -synonyms FILE -comments FILE -query ID [-options]
  Example:
    parentage_report.pl -par parentage.tsv \
                        -syn parentage-synonyms.tsv \
                        -com parentage-comments.tsv \
                        -query Hardin

  Given the requried input data, generate a report about an individual, including the pedigree,
  any aliases/synonyms for the line, the lines which have the individual in their pedigree,
  and any available comments about the individual.

  Some other lines to try, to check various characteristics of the data:
    Hardin, Hayes, Hamlin, Gnome, Franklin, Flyer, Flambeau, Williams, "Williams 82", Lee

  Required:
    -parents    File with three columns: individuals and parents individuals and the parents;
    -synonyms   File with two columns: individual and synonym (if multiple synonyms, one line for each);
    -comments   File with two columns: individual and comments
    -query      ID of an individual for which to generate a report

  Options:
    -max_ped_size  The maximum number of individuals in the pedigree to report.
    -verbose  Report some intermediate information.
    -help     This message.
```

### Example: Generate a full report for a specified query (genotype)

```
  ./parentage_report.pl -par data/parentage.tsv \
                        -syn data/parentage-synonyms.tsv \
                        -com data/parentage-comments.tsv \
                        -query Hardin \
                        -max_ped_size 10
```

This generates the following report:
```
  Pedigree of Hardin (showing first the immediate parents, then progressively earlier crosses):
  Hardin ==	( Corsoy 3 , Cutler 71 )
  Hardin ==	( Corsoy 3 , ( Cutler 4 , SL5 ) )
  Hardin ==	( Corsoy 3 , ( Cutler 4 , ( ( Kent 7 , L49-4196 ) , ( Kent 8 , Mukden ) ) ) )
  
  
  Hardin is in the pedigree of these lines: 05KL119276, 05KL135608, Asgrow A2242, MT002989, OW1012750, PI 669396, Syngenta S16-Y6, XP1928
  
  Alternate names for Hardin: PI 548526, A76-102009
  
  Comments for Hardin: PVP 8100052

```

### Example: Calculate pedigree strings for all genotypes in the input parent file

Report the output as a table of genotype-parent-parent triples and a tree-like pedigree string
(the default output option), and limit the reported pedigree size by setting `max_ped_size 10`.
Note: given the example data, with 14740 individuals with corresponding parents indicated, pedigrees 
are generated for each; below, only the first 10 lines of the output are shown.

```
  ./parentage.pl -parents data/parentage.tsv -max 10 | head    
  
  ## 1 ##
  00CY622138 ==	( ( B152 , B231 ) , 11415 ) 
  ## 2 ##
  02JR310007 ==	( CM4035N , Pioneer P93B82 ) 
  02JR310007 ==	( CM4035N , ( Pioneer P9273 , ( ( MO304 , Asgrow A3127 ) , ( Asgrow 3733 , Resnik ) ) ) ) 
  02JR310007 ==	( CM4035N , ( ( Pioneer P2981 , Asgrow A3127 ) , ( ( MO304 , Asgrow A3127 ) , ( Asgrow 3733 , Resnik ) ) ) ) 
  02JR310007 ==	( CM4035N , ( ( ( Hark , ( Corsoy , Calland ) ) , Asgrow A3127 ) , ( ( MO304 , Asgrow A3127 ) , ( Asgrow 3733 , Resnik ) ) ) ) 
  !! Terminating search because number of individuals is greater than max_ped_size 10
  ## 3 ##
  02JR310007BC1 ==	( 02JR310007 , ( 02JR310007 , 3607F9-AOYN ) ) 
```

### Example: Report input data and pedigree string for an indicated genotype

Report the output as a table of genotype-parent-parent triples, with header line. 
This can be written to a file and used as input to the [Helium pedigree viewer](https://helium.hutton.ac.uk/#/pedigree)

```
  ./parentage.pl -p data/parentage.tsv -f table0 -q Essex 

  Genotype	FemaleParent	MaleParent
  Essex	Lee	S5-7075
  Lee	S-100	C.N.S.
  S5-7075	N48-1248	Perry
  N48-1248	Roanoke	N45-745
  N45-745	Ogden	C.N.S.
  Ogden	Tokyo	PI 54610
  Perry	Patoka	L37-1355

```

Here is the pedigree image generated by the [Helium pedigree viewer](https://helium.hutton.ac.uk/#/pedigree) from the input above (for `-query Essex`):

![Essex](https://github.com/soybase/parentage/blob/main/examples/images/Essex.png)

Here is the corresponding pedigree string, generated with <br>
`./parentage.pl -parents data/parentage.tsv -q Essex -f string`
```
Essex ==	( Lee , S5-7075 ) 
Essex ==	( ( S-100 , C.N.S. ) , S5-7075 ) 
Essex ==	( ( S-100 , C.N.S. ) , ( N48-1248 , Perry ) ) 
Essex ==	( ( S-100 , C.N.S. ) , ( ( Roanoke , N45-745 ) , Perry ) ) 
Essex ==	( ( S-100 , C.N.S. ) , ( ( Roanoke , ( Ogden , C.N.S. ) ) , Perry ) ) 
Essex ==	( ( S-100 , C.N.S. ) , ( ( Roanoke , ( ( Tokyo , PI 54610 ) , C.N.S. ) ) , Perry ) ) 
Essex ==	( ( S-100 , C.N.S. ) , ( ( Roanoke , ( ( Tokyo , PI 54610 ) , C.N.S. ) ) , ( Patoka , L37-1355 ) ) ) 
```
