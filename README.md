# Sheeple
A Shell to Perl compiler written in Perl. The program takes a shell script as input and outputs an equivalent Perl program.

## 1. Usage
The program is written in a single file [sheeple.pl](./sheeple.pl). Clone the repo or download a zip, and then on a linux terminal:
```
cd sheeple
chmod sheeple.pl
./sheeple.pl <file path to shell script>
```
The resulting perl program will be output to STDOUT.

## 2. Subset of Shell syntax covered
|  Level | Syntax | Keywords | Builtins Programs | Variables | Explanation |
| ------ |------- | -------- | ----------------- | --------- | ----------- |
| 0      | `=`<br>`$`<br>`#`  |          |        `echo`       |           | Only simple & obvious statements
| 1      | `?`<br>`*`<br>`[ ]` |`for`<br>`do`<br>`done`|`exit`<br>`read`<br>`cd`       |           | Only simple & obvious statements<br>**`? * [ ]`** for file matching only
| 2      | `'`<br>`"`  |`if`<br>`then`<br>`elif`<br>`else`<br>`fi`<br>`while`|`test`<br>`expr`| `$1`<br>`$2`<br>`$3` | Only simple & obvious statements<br>No nesting
| 3      | <code>\`</code><br>`$()`<br>`$(())`<br>`[ ]` |          | `echo -n` | `$#`<br>`$*`<br>`$@` | nested loops and/or conditions<br>`$()` as equivalent to back quotes<br>`$(())` for arithmetic<br>`[ ]` as equivalent to test
| 4      | `< >`<br>`&&`<br>`\|\|`<br>`;`<br>`{}` | `case`<br>`esac`<br>`local`<br>`return` | `mv`<br>`chmod`<br>`ls`<br>`rm`|   |`)` as part if case only<br>`{}` for functions only<br>`mv`/`chmod`/`ls`/`rm` with no command line options
