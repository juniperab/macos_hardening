#!/usr/bin/env zsh

#
#  ^. .^
#  (=°=)
#  (n  n )/  HardeningDoggy
#


CYAN='\033[0;36m'
RED='\033[0;31m'
REDBOLD='\033[1;31m'
YELLOWBOLD='\033[1;33m'
YELLOW='\033[0;33m'
#PURPLE='\033[0;35m'
PURPLEBOLD='\033[1;35m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
MAXIMUMPOINTS=0
POINTSARCHIVED=0

################################################################################
#                                                                              #
#                                 FUNCTIONS                                    #
#                                                                              #
################################################################################


#
# Usage function
#
function Usage() {
  echo "Usages: "
  echo "  ./doggy.sh -h"
  echo "  ./doggy.sh [mode]"
  echo "  ./doggy.sh [mode [options]]"
  echo "  ./doggy.sh [mode] [file <file.csv>]"
  echo "  ./doggy.sh [mode [options]] [global options] [file <file.csv>]"
  echo ""
  echo "  -h | --help                   : help method"
  echo "  mode :"
  echo "    -s | --status               : read configuration"
  echo "    -a | --audit                : audit configuration"
  echo "    options :"
  echo "        -skipu | --skip-update     : to skip software update verification in audit mode"
  echo "    -b | --backup               : save your configuration in csv file"
  echo "  file :"
  echo "    -f | --file                 : csv file containing list of policies"
}

#
# Convertor functions
#

# Convert numerical boolean to string boolean
function NumToStingBoolean() {
  if [[ "$1" == 1 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Convert string boolean to numerical boolean
function StringToNumBoolean() {
  if [[ "$1" == "true" ]]; then
    echo "1"
  else
    echo "0"
  fi
}

#
# Messages functions
#

# Simple message
function SimpleMessage() {
  echo "[ ] $1"
}

# Warning message
function WarningMessage() {
  echo -e "${YELLOW}[!] $1${NC}"
}

# Alert messages
function AlertMessage() {
  echo -e "${RED}[x] $1${NC}"
}
function AlertHightMessage() {
  echo -e "${PURPLEBOLD}[X] $1${NC}"
}
function AlertMediumMessage() {
  echo -e "${REDBOLD}[/] $1${NC}"
}
function AlertLowMessage() {
  echo -e "${YELLOWBOLD}[~] $1${NC}"
}

# Success message
function SuccessMessage() {
  echo -e "${GREEN}[-] $1${NC}"
}

#
# Backup function
#
function Save() {
  echo "$1" >> "$BACKUPFILE"
}

#
# First print
#

# Intro
function Intro() {
  echo ""
  echo ""
  echo "                             ^. .^                                   "
  echo "                             (=°=)                                   "
  echo "                             (n  n )/  HardeningDoggy                "
  echo ""
  echo ""
}

# Config
function FirstPrint() {
  echo "User name               : $USER"
  echo "Mode to apply           : $MODE"
  echo "Hostname                : $(hostname)"
  echo "CSV File configuration  : $INPUT"
}

#
# Print result (STATUS mode)
# INPUT : ID, Name, ReturnedExit, ReturnedValue
#
function PrintResult() {
  local ID=$1
  local Name=$2
  local ReturnedExit=$3
  local ReturnedValue=$4

  case $ReturnedExit in
    0 )# No Error
      # if RecommendedValue is empty (not defined)
      if [[ -z "$RecommendedValue" ]]; then
        WarningMessage "$ID : $Name ; Warning : policy does not exist yet"
      # if RecommendedValue is defined
      else
        #MESSAGE="$ID : $Name ; ActualValue = $ReturnedValue ; RecommendedValue = $RecommendedValue"
        MESSAGE=$(printf "%-6s %-55s %-11s %s \n" "$ID" "$Name" "$ReturnedValue" "$RecommendedValue")
        SimpleMessage "$MESSAGE"
      fi
      ;;
    
    26 )#Warning
      MESSAGE=$(printf "%-6s %-55s %-11s %s \n" "$ID" "$Name" "N/A" "$RecommendedValue")
      WarningMessage "$MESSAGE"
      ;;
    
    * )#Error
    AlertMessage "$ID : $Name ; Error : The execution caused an error"
      ;;
  esac
}

#
# Print result with colors depending on the status (AUDIT mode)
# INPUT : ID, Name, ReturnedExit, ReturnedValue, RecommendedValue, Severity
#
function PrintAudit() {
  local ID=$1
  local Name=$2
  local ReturnedExit=$3
  local ReturnedValue=$4
  local RecommendedValue=$5
  local Severity=$6
  MAXIMUMPOINTS=$((MAXIMUMPOINTS+4))

  case $ReturnedExit in
    0 )#No Error
      # if RecommendedValue is empty (not defined)
      if [[ -z "$RecommendedValue" ]]; then
        WarningMessage "$ID : $Name ; Warning : policy does not exist yet"
      # if RecommendedValue is defined
      else
        #MESSAGE="$ID : $Name ; ActualValue = $ReturnedValue ; RecommendedValue = $RecommendedValue"
        MESSAGE=$(printf "%-6s %-55s %-11s %s \n" "$ID" "$Name" "$ReturnedValue" "$RecommendedValue")
        if [[ "$RecommendedValue" == "$ReturnedValue" ]]; then
          POINTSARCHIVED=$((POINTSARCHIVED+4))
          SuccessMessage "$MESSAGE"
        elif [[ ($(echo "$RecommendedValue" | cut -c1-3) == "<= ") && ("$ReturnedValue" -le $(echo "$RecommendedValue" | cut -c4-)) ]]; then
          POINTSARCHIVED=$((POINTSARCHIVED+4))
          SuccessMessage "$MESSAGE"
        elif [[ ($(echo "$RecommendedValue" | cut -c1-3) == ">= ") && ("$ReturnedValue" -ge $(echo "$RecommendedValue" | cut -c4-)) ]]; then
          POINTSARCHIVED=$((POINTSARCHIVED+4))
          SuccessMessage "$MESSAGE"
        elif [[ ($(echo "$RecommendedValue" | cut -c1-2) == "< ") && ("$ReturnedValue" -lt $(echo "$RecommendedValue" | cut -c3-)) ]]; then
          POINTSARCHIVED=$((POINTSARCHIVED+4))
          SuccessMessage "$MESSAGE"
        elif [[ ($(echo "$RecommendedValue" | cut -c1-2) == "> ") && ("$ReturnedValue" -gt $(echo "$RecommendedValue" | cut -c3-)) ]]; then
          POINTSARCHIVED=$((POINTSARCHIVED+4))
          SuccessMessage "$MESSAGE"
        elif [[ ($(echo "$RecommendedValue" | cut -c1-3) == "!= ") && ("$ReturnedValue" -ne $(echo "$RecommendedValue" | cut -c4-)) ]]; then
          POINTSARCHIVED=$((POINTSARCHIVED+4))
          SuccessMessage "$MESSAGE"
        else
          case $Severity in
            "High" )
            POINTSARCHIVED=$((POINTSARCHIVED+0))
            AlertHightMessage "$MESSAGE"
              ;;
            "Medium" )
            POINTSARCHIVED=$((POINTSARCHIVED+1))
            AlertMediumMessage "$MESSAGE"
              ;;
            "Low" )
            POINTSARCHIVED=$((POINTSARCHIVED+2))
            AlertLowMessage "$MESSAGE"
              ;;
          esac
        fi
      fi
      ;;
    
    26 )#Warning
    MESSAGE=$(printf "%-6s %-55s %-11s %s \n" "$ID" "$Name" "N/A" "$RecommendedValue")
    WarningMessage "$MESSAGE"
      ;;
    
    * )#Error
    AlertMessage "$ID : $Name ; Error : The execution caused an error"
      ;;
  esac
}

#
# Test if type is correct
# INPUT : TYPE
#
function GoodType() {
  local TYPE=$1
  if [[ "$TYPE" =~ ^(string|data|int|float|bool|date|array|array-add|dict|dict-add)$ ]]; then
    # Good type
    return 1
  else
    # Type is not correct
    return 0
  fi
}

#
# Transform generic sudo option with correct option
# Example : -u <usename> -> -u steavejobs
#
function SudoUserFilter() {
  case $SudoUser in
    "username" )
      SudoUser="$(logname)"
      ;;
    *)
      SudoUser="root"
      ;;
  esac
}

################################################################################
#                                                                              #
#                                  OPTIONS                                     #
#                                                                              #
################################################################################


POSITIONAL=()
SKIP_UPDATE=false
MODE="AUDIT"
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      Usage
      exit 1
      ;;
    -a|--audit)
      MODE="AUDIT"
      shift # past argument
      ;;
    -s|--status)
      MODE="STATUS"
      shift # past argument
      ;;
    -b|--backup)
      MODE="BACKUP"
      shift # past argument
      ;;
    -f|--file)
      INPUT="$2"
      shift # past argument
      shift # past value
      ;;
    -u|--skip-update)
      SKIP_UPDATE=true
      shift # past argument
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done


## Define default CSV File configuration ##
if [[ -z $INPUT ]]; then #if INPUT is empty
  INPUT='finding_list.csv'
fi

set -- "${POSITIONAL[@]}" # restore positional parameters

## backup init file
if [[ "$MODE" == "BACKUP" ]]; then
  #BACKUPFILE=$(date +"backup-$USER-%y%m%d-%H%M.csv")
  BACKUPFILE="backup.csv"
  # remove file if it already exit
  if [[ -f "$BACKUPFILE" ]]; then
    rm "$BACKUPFILE"
  fi

  Save "ID,Category,Name,AssessmentStatus,Method,MethodOption,GetCommand,PostProcessCommand,User,RegistryPath,RegistryItem,ExpectedExit,RecommendedValue,TypeValue,Operator,Severity,Level"
fi

HOSTNAME=`hostname | awk -F. '{print $1}'`

################################################################################
#                                                                              #
#                                 MAIN CODE                                    #
#                                                                              #
################################################################################

#
# Print Intro
#
Intro

#
# First print with some caracteritics environnement
#
echo "################################################################################"
FirstPrint
echo "################################################################################"
echo ""

#
# Verify all Apple provided software is current
#
ID='1000'
if [[ "$SKIP_UPDATE" == false ]]; then
  echo "################################################################################"
  EXPECTED_OUTPUT_SOFTWARE_UPDATE="SoftwareUpdateToolFindingavailablesoftware"
  if [[ $MODE == "AUDIT" ]]; then
    echo "Verify all Apple provided software is current..."

    # command
    COMMAND="softwareupdate -l"

    ReturnedValue=$(eval "$COMMAND" 2>&1)
    ReturnedExit=$?

    ReturnedValue=${ReturnedValue//[[:space:]]/} # we remove all white space

    if [[ "$ReturnedValue" == "$EXPECTED_OUTPUT_SOFTWARE_UPDATE" ]]; then
      SuccessMessage "Your software is up to date !"
    else
      AlertHightMessage "You have to update your software."
      SimpleMessage "Remediation 2 : with command 'sudo softwareupdate -ia'"
    fi
  fi
  echo "################################################################################"
fi


### Global varibles
PRECEDENT_CATEGORY=''
PRECEDENT_SUBCATEGORY=''

## Save old separator
OLDIFS=$IFS
## Define new separator
IFS=','

## If CSV file does not exist
if [ ! -f $INPUT ]; then
  echo "$INPUT file not found";
  exit 99;
fi
while read -r ID Category Name AssessmentStatus Method MethodOption GetCommand PostProcessCommand SudoUser RegistryPath RegistryItem ExpectedExit RecommendedValue TypeValue Operator Severity Level
do
  ## Print first raw with categories
  if [[ $ID == "ID" ]]; then
    ActualValue="Actual"
    RecommendedValue="Recommended"
    FIRSTROW=$(printf "%6s %9s %55s %s \n" "$ID" "$Name" "$ActualValue" "$RecommendedValue")
    echo -ne "$FIRSTROW"
  ## We will not take the first row
  else
    
    

    #
    ############################################################################
    #                           STATUS AND AUDIT MODE                          #
    ############################################################################
    #
    if [[ "$MODE" == "STATUS" || "$MODE" == "AUDIT" || "$MODE" == "BACKUP" ]]; then

      #
      # Compute RecommendedValue when necessary
      #
      if [[ $(echo "$RecommendedValue" | cut -c1) == '`' ]]; then
        RecommendedValue=$(echo "$RecommendedValue" | cut -c2- | rev | cut -c2- | rev)
        RecommendedValue=$(eval "$RecommendedValue")
      fi
      
      #
      # RecommendedValue boolean filter
      #
      if [[ "$TypeValue" == "bool" ]]; then
        RecommendedValue=$(StringToNumBoolean "$RecommendedValue")
      fi
      
      #
      # Apply Operator to RecommendedValue when it is not "="
      #
      if [[ "$Operator" != "=" ]]; then
        RecommendedValue="$Operator $RecommendedValue"
      fi
      
      #
      # Set default expected exit code
      #
      if [[ "$ExpectedExit" == "" ]]; then
        ExpectedExit=0
      fi
      
      #
      # Fix commas in values
      #
      PostProcessCommand="$(echo "$PostProcessCommand" | sed "s/<COMMA>/,/g")"

      #
      # Print category
      #
      if [[ "$PRECEDENT_CATEGORY" != "$Category" ]]; then
        echo #new line
        echo "--------------------------------------------------------------------------------"
        DateValue=$(date +"%D %X")
        echo "[*] $DateValue Starting Category $Category"
        PRECEDENT_CATEGORY=$Category
      fi

      #
      # Print subcategory
      #
      SubCategory=${Name%:*} # retain the part before the colon
      Name=${Name##*:} # retain the part after the colon
      if [[ "$PRECEDENT_SUBCATEGORY" != "$SubCategory" ]]; then
        echo "------------$SubCategory"
        PRECEDENT_SUBCATEGORY=$SubCategory
      fi

      ###################################
      #        CASE METHODS             #
      ###################################


      # STATUS/AUDIT
      # Registry
      #
      if [[ "$Method" == "Registry" ]]; then

        # command
        COMMAND="defaults $MethodOption read $RegistryPath $RegistryItem"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        if [[ "$ReturnedExit" == "$ExpectedExit" ]]; then
          ReturnedExit=0
        elif [[ "$ReturnedExit" == 1 ]]; then
          # if an error occurs, it's caused by non-existance of the couple (file,item)
          # we will not consider this as an error, but as an warning
          ReturnedExit=26
        fi


      # STATUS/AUDIT
      # PlistBuddy (like Registry with more options)
      #
      elif [[ $Method == "PlistBuddy" ]]; then

        # command
        COMMAND="/usr/libexec/PlistBuddy $MethodOption \"Print $RegistryItem\" $RegistryPath"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        if [[ "$ReturnedExit" == "$ExpectedExit" ]]; then
          ReturnedExit=0
        elif [[ "$ReturnedExit" == 1 ]]; then
          # if an error occurs, it's caused by non-existance of the couple (file,item)
          # we will not consider this as an error, but as an warning
          ReturnedExit=26
        fi


      # STATUS/AUDIT
      # launchctl
      # intro : Interfaces with launchd to load, unload daemons/agents and generally control launchd.
      # requirements : $RegistryItem
      #
      elif [[ "$Method" == "launchctl" ]]; then

        # command
        COMMAND="launchctl print system/$RegistryItem"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        if [[ "$ReturnedExit" == "$ExpectedExit" ]]; then
          ReturnedValue="enable"
          ReturnedExit=0
        elif [[ "$ReturnedExit" == 1 ]]; then
          # if an error occurs, it's caused by non-existance of the item
          # we will not consider this as an error, but as an warning
          ReturnedExit=26
        elif [[ $ReturnedExit == 113 ]]; then
          # if an error occurs (113 code), it's caused by non-existance of the RegistryItem in system
          # so, it's not enabled
          ReturnedExit=0
          ReturnedValue="disable"
        else
          ReturnedValue="enable"
        fi


      # STATUS/AUDIT
      # csrutil (Intergrity Protection)
      #
      elif [[ $Method == "csrutil" ]]; then

        # command
        COMMAND="csrutil $GetCommand"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        # clean retuned value
        if [[ $ReturnedValue == "System Integrity Protection status: enabled." ]]; then
          ReturnedValue="enable"
        else
          ReturnedValue="disable"
        fi


      # STATUS/AUDIT
      # spctl (Gatekeeper)
      #
      elif [[ $Method == "spctl" ]]; then

        # command
        COMMAND="spctl $GetCommand"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        # clean retuned value
        if [[ $ReturnedValue == "assessments enabled" ]]; then
          ReturnedValue="enable"
        else
          ReturnedValue="disable"
        fi


      # STATUS/AUDIT
      # systemsetup
      #
      elif [[ $Method == "systemsetup" ]]; then

        # command
        COMMAND="sudo systemsetup $GetCommand"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        # clean retuned value
        ReturnedValue="${ReturnedValue##*:}" # get content after ":"
        ReturnedValue=$(echo "$ReturnedValue" | tr '[:upper:]' '[:lower:]') # convert to lowercase
        ReturnedValue="${ReturnedValue:1}" # remove first char (space)


      # STATUS/AUDIT
      # pmset
      #
      elif [[ $Method == "pmset" ]]; then

          # command
          COMMAND="pmset -g | grep $RegistryItem"

          ReturnedValue=$(eval "$COMMAND" 2>&1)
          ReturnedExit=$?

          # clean returned value
          ReturnedValue="${ReturnedValue//[[:space:]]/}" # we remove all white space
          ReturnedValue="${ReturnedValue#"$RegistryItem"}" # get content after RegistryItem


      # STATUS/AUDIT
      # fdesetup (FileVault)
      #
      elif [[ "$Method" == "fdesetup" ]]; then

        # command
        COMMAND="fdesetup $GetCommand"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        # clean retuned value
        if [[ "$ReturnedValue" == "FileVault is Off." ]]; then
          ReturnedValue="disable"
        else
          ReturnedValue="enable"
        fi

      # STATUS/AUDIT
      # nvram
      #
      elif [[ "$Method" == "nvram" ]]; then

        # command
        # we add '|| true' because grep return 1 when it does not find RegistryItem
        COMMAND="nvram -p | grep -c '$RegistryItem' || true"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

      # STATUS/AUDIT
      # AssetCacheManagerUtil
      #
      elif [[ "$Method" == "AssetCacheManagerUtil" ]]; then

        # command
        COMMAND="sudo AssetCacheManagerUtil $GetCommand"

        ReturnedValue=$(eval "$COMMAND" 2>&1)
        ReturnedExit=$?

        # when this command return 1 it's not an error, it's just beacause cache saervice is deactivated
        if [[ "$ReturnedExit" == '1' ]]; then
          ReturnedExit=0
          ReturnedValue='deactivate'
        else
          ReturnedValue='activate'
        fi


      fi
    fi
    
    ## Post Processing
    
    if [[ "$PostProcessCommand" != "" ]]; then
      ReturnedValue=$(echo "$ReturnedValue" | eval $PostProcessCommand)
    fi

    ## Result printing
    case "$MODE" in
      "STATUS" )
        PrintResult "$ID" "$Name" "$ReturnedExit" "$ReturnedValue"
        ;;
      "AUDIT" )
        PrintAudit "$ID" "$Name" "$ReturnedExit" "$ReturnedValue" "$RecommendedValue" "$Severity"
        ;;
      "BACKUP" )
        #echo "$ID, $ReturnedValue"
        Save "$ID,$Category,$Name,$AssessmentStatus,$Method,$MethodOption,$GetCommand,$PostProcessCommand,$SudoUser,$RegistryPath,$RegistryItem,$ExpectedExit,$ReturnedValue,$TypeValue,$Operator,$Severity,$Level"
        ;;
    esac


  fi

  # Out of main condition to take first line of csv file
  # reset some values
  ReturnedExit=""
  ReturnedValue=""
done < $INPUT

## Redefine separator with its precedent value
IFS=$OLDIFS

################################################################################
#                                END OF PROCESS                                #
################################################################################

if [[ $MODE == "AUDIT" ]]; then
  echo ""
  echo "#################################### SCORE #####################################"
  echo ""
  echo "total points : $MAXIMUMPOINTS"
  echo "points archived : $POINTSARCHIVED"
  VALUE=$(bc -l <<< "($POINTSARCHIVED/$MAXIMUMPOINTS)*5+1")
  echo "Score : ${VALUE:0:4} / 6"
fi
