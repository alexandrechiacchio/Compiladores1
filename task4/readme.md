In this, the task is to create a slighty less crude javascript compiler from a given set of contructions and intructions.

Now, the stack machine supports:
  * funtion calls with activation records and scope
  * scope as intended with {} in javascript
  * asm mode, i.e.,  stack machine language in javascript code using ```asm{ stack code here }``` that directly adds code to compiled form.
  Example:
```
  function log( msg ) {
  msg asm{println # undefined};
}

log( 'Hello, world!' );
```

Which compiles to:

```
log & log {} = '&funcao' 16 [=] ^
'Hello, world!' 1 log @ $ ^
.
msg & msg arguments @ 0 [@] = ^
msg @ println # undefined ^
undefined @ '&retorno' @ ~
```