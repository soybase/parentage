### Overview  <a name="overview"/>

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
    -format   Output format. Options: string, table. Either or both (string,table) can be specified. [string]
    -last_only     For string format, print only the last pedigree string; otherwise, print one for each data line.
    -max_ped_size  The maximum number of individuals in the pedigree to report.
                        When this number is reached, the pedigree of that size will be reported,
                        even if other parents may be found in the input data.
    -verbose  Report some intermediate information.
    -help     This message.
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
```

### Example: Report input data and pedigree string for an indicated genotype

Report the output as a table of genotype-parent-parent triples, with header line. 
This can be written to a file and used as input to the [Helium pedigree viewer](https://helium.hutton.ac.uk/#/pedigree)

```
  ./parentage.pl -p data/parentage.tsv -f table -q Essex | grep "::" | perl -pe 's/.+ ::\t//' > Essex.tsv

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
