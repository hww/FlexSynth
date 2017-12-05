@cls
zmados -l -pZ86E40 -o -x -t main.s
@if errorlevel 1 goto end
@echo.
@echo.
zlddos main.cmd
@move A.LD main.LD
@echo.
zlddos -a -g -mmain.map -omain.hex main.cmd
:end
