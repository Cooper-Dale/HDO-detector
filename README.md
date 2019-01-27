# HDO-detector
ČEZ Distribuce, a. s. id annoncing their electrical network peak ond off-peak hours (HDO) for their regions (e.g. Sever) and your home appliance code (e.g. A1B6DP1). 
One can configure its details at https://www.cezdistribuce.cz/cs/pro-zakazniky/spinani-hdo.html, you have to know:
* your region in the Czech republic 
* your code (A1B6DP1) or command (P64) or command code (181)
* ! in ones house, there can be used more than code (i.e. A1B6DP1 and A1B6DP2) with different time schedulle

Data are published in json format for the winter and summer period and my script is looking for:
* working day (Po - Pá) or weekend (So - Ne)
* cuernt time
* off peak is it active (casZap1) or inactive (casVyp1)
Data are published via nginx www sever for Home Assistant to be consumed as state 0 or 1. For the user there is another published file to see whed there will be a state change. 

# HELP WANTED
Next goal is to convert this script to Home Assistant component.
* config: region and code (or command or command code) - I am using just the code
* name: binary_sensor.cez_distribuce_hdo-custom_name
* binary state
 atributes:
* next change time
* last change time
* command - should be considered as private
* region
* last json download date / time - json is valid for 6 months, but daily check is recomended

