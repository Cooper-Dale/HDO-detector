#!/bin/bash
#by Cooper 15.11.2015
#27.1.2019 - no longer http, just https
echo "*************** HDO ***************"
datum=$(date "+%Y-%m-%d %H:%M:%S")
jsonfile="/tmp/hdo.json"
cezfile="https://www.cezdistribuce.cz/edee/content/sysutf/ds3/data/hdo_data.json?&code=A1B6DP1&regionSever=1&region=regionSever&regionText=Sever"
echo ted je prave $datum

function stahniCEZ() {
    echo .............curl
    curl -m 10 -N -X GET $cezfile -o $jsonfile

    #detekce víkendu
    if [[ $(date +%u) -lt 6 ]] ; then
        jsonw="Po - Pá"
        vikend="není"
        vikendlog="Po-Pa"
       else
        jsonw="So - Ne"
        vikend="je"
        vikendlog="So-Ne"
    fi
    #data do logu
    echo .............json
    zmena=$(sed -n 's/^.*date": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)    
    sezona=$(sed -n 's/^.*description": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)
    validFrom=$(sed -n 's/^.*validFrom": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)
    validTo=$(sed -n 's/^.*validTo": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)
    sazba=$(sed -n 's/^.*sazba": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)
    doba=$(sed -n 's/^.*doba": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)
    povel=$(sed -n 's/^.*povel": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)
    kodPovelu=$(sed -n 's/^.*kodPovelu": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)
    id=$(sed -n 's/^.*id": "\(.*\)",\{0,1\}/\1/p' $jsonfile | head -1)              

    dneska=$(date +%A)
    echo sezóna: $sezona";" naposledy změněno $zmena";" dnes je $dneska a $vikend víkend
    echo $datum"; "$sezona"; "$zmena"; "$validFrom"; "$validTo"; "$sazba"; "$doba"; "$povel"; "$kodPovelu"; "$id"; "$vikendlog >> /var/log/my-HDO.log

    linenum=$(grep -ne "$jsonw" $jsonfile | sed 's/\(^..\).*/\1/')

    #echo číslo řádku s dnem v týdnu: $linenum
    linenummin=$(( linenum + 2 ))
    linemummax=$(( linenum + 21 ))
    #echo $linenummin a $linemummax
    #sed -n "53,72p" < $jsonfile
    casy=$(sed -n "${linenummin},${linemummax}p" < $jsonfile)
    echo $casy > /tmp/casy.tmp

}

if [ ! -f $jsonfile ]; then
    echo "Soubor neexistuje, stahuji ho znovu ..."
    stahniCEZ
fi
if test `find $jsonfile -mmin +1440`
then
    echo "Json z ČEZ je víc než den starý, stahuji nový ..."
    stahniCEZ
    else
    echo "data existuji a jsou cerstva - OK"
    #stahniCEZ  #pak zrušit
fi

if [[ $(find $jsonfile -type f -size +10c 2>/dev/null) ]]; then
    echo "je větší než 10b a asi obsahuje data"
else
    echo "je menší než 10b a asi neobsahuje nic, stahuji nový"
    stahniCEZ
fi


casTED=$(date "+%H:%M")
echo .............HDO $casTED

while read casHDO; do
   if [[ $casHDO > $casTED ]] ; then
 #  if [[ $casHDO > "11:00" ]] ; then
      compHDO="bude za"
      nextHDOtime=$casHDO
      remainHDO=$(date -u -d "$casHDO + $casTED" "+%H:%M")
      if [[ $remainHDO < 00:31 ]] ; then  #využít pro upozornìní na blížící se HDO
            soonHDOtext="jiz brzy"
            #HDO LED
            break 
            else
            soonHDOtext="za dlouho"
            #HDO LED
            break 
            fi
      else 
      compHDO="bylo pred"
      #HDO LED
      remainHDO=$(date -u -d "$casTED + $casHDO" "+%H:%M") 
    fi
    #echo $casHDO"," $compHDO $remainHDO $soonHDOtext
    #echo $casHDO "-" $casTED"," $compHDO $remainHDO $soonHDOtext
    
done < <(grep -o '[0-9]\{2\}:[0-9]\{2\}' /tmp/casy.tmp)
#dùležité je kde je první bude, z toho se urèí co nastane a co asi teï bìží, když je první bude casVypX je jasné že je HDO zapnuté


# regex pro operaci .*"cas\(.*\)[[:digit:]]": "23:59".*

#cat /tmp/casy.tmp | sed "s/.*\"cas\(.*\)[[:digit:]]\": \"23:59\".*/\1/"
nextHDOstate=$(cat /tmp/casy.tmp | sed "s/.*\"cas\(.*\)[[:digit:]]\": \"$nextHDOtime\".*/\1/")
if  [ $nextHDOstate != "Vyp" ] && [ $nextHDOstate != "Zap" ] ; then currentHDOstate=9 ; HDOled="white" ; echo "***** chyba cteni stavu!"; fi
if  [ $nextHDOstate == "Vyp" ] ; then currentHDOstate=1 ; HDOled="green" ; fi
if  [ $nextHDOstate == "Zap" ] ; then currentHDOstate=0 ; HDOled="red" ; fi
if  [ $nextHDOstate == "Zap" ] && [ $soonHDOtext == "jiz brzy" ] ; then HDOled="orange" ; fi
#logovani
echo $nextHDOtime $soonHDOtext za $remainHDO "- prijde povel" $nextHDOstate", nyni je stav" $currentHDOstate
echo $datum","$currentHDOstate","$nextHDOtime","$soonHDOtext","$remainHDO","$HDOled >> /var/tmp/hdo_state.log
#výpis je na jeden řádek, ne jak echo s odřádkováním na konci
printf "$datum, HDO: $currentHDOstate, Pristi zmena: $nextHDOtime, tj. $soonHDOtext - $remainHDO" > /var/tmp/hdo_state_tmp.log
printf "$currentHDOstate" > /usr/share/nginx/www/hdo.state
printf "$HDOled" > /usr/share/nginx/www/hdo.led

echo .............END ...
