### Overview  <a name="overview"/>

```
  Usage:  parentage.pl -parents FILE [-options]

  Given a file of individuals and parents, recursively determine the pedigree
  (the parentage going back as many generations as possible) for an individual.
  Can be calculated for a single indicated individual or for all in the parents file.

  The parents file should be structured like this.
  The individual (progeny) is on the left, and the parent(s) are on the right
    indID  parent1  parent2
    A      B        C
    D      B        C
    E      B        F
    G      H        -    # an individual with only one parent
    I      -        H    # another individual with only one parent

  Required:
    -parents  File listing the individuals and parents

  Options:
    -query    ID of an individual for which to calculate parentage.
              If not provided, report parentage for all individuals.
    -format   Output format. Options: string, table. Either or both (string,table) can be specified. [table]
    -noself   Remove the query ID from the parentage string.
    -verbose  Report some intermediate information.
    -help     This message.
```

### Example: Calculate pedigree strings for all genotypes in the input parent file

Report the output as a table of genotype-parent-parent triples and a tree-like pedigree string

```
  ./parentage.pl -parents parents_clean1.tsv -format table,string | head -7
    
    Hale_Ogden_#12	Ogden	-
    Ogden	Tokyo	PI_54610
    Tokyo	PI_8424	-
    Hale_Ogden_#12: ( Hale_Ogden_#12 ( Ogden ( Tokyo ( PI_8424 , - ) , PI_54610 ) , - ) )
    
    70653G003	Pioneer_P9594	Syngenta_S59-60
    70653G003: ( 70653G003 ( Pioneer_P9594 , Syngenta_S59-60 ) )
    ...
```

### Example: Report input data and pedigree string for an indicated genotype

Report the output as a table of genotype-parent-parent triples, with header line. 
This can be written to a file and used as input to the [Helium pedigree viewer](https://helium.hutton.ac.uk/#/pedigree)

```
  ./parentage.pl -parents parents_clean1.tsv -q YB57H

    Genotype	Female Parent	Male Parent
    YB57H	8377-16	W8238-02
    8377-16	Pioneer_P9582	W2707-23
    W2707-23	Y2011Z2	Epps
    Y2011Z2	1190-02	J74-45
    1190-02	Mack	Forrest
    W8238-02	Pioneer_P9591	Y277402
    Y277402	1100-07	1190-19
    1100-07	Forrest	Tracy
    1190-19	Mack	Forrest
```
