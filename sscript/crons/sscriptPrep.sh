#!/bin/bash
SARCHIVEDIR=/share/sarchive/

# Safe directory iteration using a while-read loop to handle spaces safely
find "${SARCHIVEDIR}" -mindepth 1 -maxdepth 1 -type d -mtime -1 -print0 | while IFS= read -r -d '' JOBDIR; do
    
    chmod o+rx "${JOBDIR}"
    
    # Safe file iteration for environment files
    find "${JOBDIR}" -name "*_environment" -mmin -2 -print0 | while IFS= read -r -d '' JOBENV; do
        
        # Verify the file is an actual file before processing
        [ -f "${JOBENV}" ] || continue
        
        # Extract the user safely
        JOBUSER=$(sed 's/\x0/\n/g' "${JOBENV}" | grep "^USER=" | cut -d= -f2)
        
        if [ -z "${JOBUSER}" ]; then
            continue
        fi
        
        # Safely derive the script filename
        JOBSCRIPT="${JOBENV/environment/script}"
        
        # Only modify ownership/permissions if they aren't already set correctly
        # This prevents constantly hitting files that are already processed
        if [ -f "${JOBSCRIPT}" ]; then
            chown "${JOBUSER}" "${JOBENV}" "${JOBSCRIPT}"
            chmod a-w "${JOBENV}" "${JOBSCRIPT}"
        else
            chown "${JOBUSER}" "${JOBENV}"
            chmod a-w "${JOBENV}"
        fi
    done
done
