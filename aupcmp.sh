#!/bin/bash

set -u

YNquestion() {
    read -p "$1 (y/n):" response
    if [[ $response == 'y' || $response == 'Y' ]]; then
        return 0
    fi
    return 1
}

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <project1> <project2>"
    echo "       projects are prefix of .aup file"
else
    aup1="$1.aup"
    aup2="$2.aup"

    declare -i count1=0
    for dir in "${1}_data"/*/; do
        data1="${dir:0:${#dir}-1}"
        count1+=1
    done
    declare -i count2=0
    for dir in "${2}_data"/*/; do
        data2="${dir:0:${#dir}-1}"
        count2+=1
    done

    if [ $count1 -ne 1 ]; then
        echo "expected 1 top level subdirectory in ${1}_data, got $count1"
    elif [ $count2 -ne 1 ]; then
        echo "expected 1 top level subdirectory in ${2}_data, got $count2"
    else
        /usr/bin/cmp "$aup1" "$aup2"
        aup_cmp_result=$?
        # return value 1 is mismatch
        if [ $aup_cmp_result -eq 1 ]; then
            YNquestion "Show diff"
            if [[ $? -eq 0 ]]; then
                /usr/bin/diff "$aup1" "$aup2"
            fi
            YNquestion "Compare audio data"
            compare_data=$?
        elif [ $aup_cmp_result -eq 0 ]; then
            echo "aup files match"
            compare_data=0
        else
            exit "$aup_cmp_result"
        fi

        if [ $compare_data -eq 0 ]; then
            declare -a dirs1 dirs2
            for dir in "${data1}"/*/; do
                s="${dir:${#data1}+1}"
                s="${s:0:${#s}-1}"
                dirs1[${#dirs1[@]}]=$s
            done
            ndirs1="${#dirs1[@]}"
            for dir in "${data2}"/*/; do
                s="${dir:${#data2}+1}"
                s="${s:0:${#s}-1}"
                dirs2[${#dirs2[@]}]=$s
            done
            ndirs2="${#dirs2[@]}"

            if [ $ndirs1 -ne $ndirs2 ]; then
                echo "$data1 has $ndirs1 directories while $data2 has $ndirs2"
                exit 3
            else
                echo "number of data directories match"
                declare -i num_mismatch_dir=0
                declare -i num_filecount_diffs=0
                declare -i num_mismatch_fname=0
                declare -i num_mismatch_files=0

                for (( i=0; i<$ndirs1; i++ )); do
                    d1=${dirs1[$i]}
                    d2=${dirs2[$i]}
                    if [[ "$d1" != "$d2" ]]; then
                        echo "non-matching directory names: $d1 $d2"
                        num_mismatch_dir+=1
                    else
                        declare -a files1 files2
                        for f in "$data1/${d1}"/*; do
                            files1[${#files1[@]}]=$f
                        done
                        nfiles1="${#files1[@]}"
                        for f in "$data2/${d2}"/*; do
                            files2[${#files2[@]}]=$f
                        done
                        nfiles2="${#files2[@]}"

                        if [ $nfiles1 -ne $nfiles2 ]; then
                            echo "$data1/${d1} has $nfiles1 files while $data2/${d2} has $nfiles2"
                            num_filecount_diffs+=1
                        else
                            echo "number of files match in ${d1}"

                            for (( i_file=0; i_file<$nfiles1; i_file++ )); do
                                path1=${files1[$i_file]}
                                path2=${files2[$i_file]}
                                f1="${path1##*/}"
                                f2="${path2##*/}"
                                if [[ "$f1" != "$f2" ]]; then
                                    echo "found mismatched file names '$f1', '$f2'"
                                    num_mismatch_fname+=1
                                else
                                    /usr/bin/cmp "$path1" "$path2"
                                    if [ $? -ne 0 ]; then
                                        num_mismatch_files+=1
                                        # TODO mismatched file name list
                                    fi
                                fi
                            done
                        fi
                    fi
                done

                if [ $num_mismatch_dir -ne 0 ]; then
                    echo "num mismatched directory names: $num_mismatch_dir"
                else
                    echo "all data directory names match"

                    if [ $num_filecount_diffs -ne 0 ]; then
                        echo "number of directories with different file counts: $num_filecount_diffs"
                    else
                        if [ $num_mismatch_fname -ne 0 ]; then
                            echo "num mismatched file names: $num_mismatch_fname"
                        else
                            echo "all au file names match"

                            if [ $num_mismatch_files -ne 0 ]; then
                                echo "num byte mismatched files: $num_mismatch_files"
                            else
                                echo "all au files byte match"
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi
fi

exit 0
