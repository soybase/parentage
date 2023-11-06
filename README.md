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
    -start    ID of an individual for which to calculate parentage.
              If not provided, report parentage for all individuals.
    -format   Output format. Options: string, table [string,table]
    -verbose  Report some intermediate information.
    -help     This message.
```
