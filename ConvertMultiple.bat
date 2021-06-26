for /r %%A in (*.ini) do (
lua53.exe XML_TO_INI_CONVERTER.lua %%A ..\CONVERTED\
)
pause