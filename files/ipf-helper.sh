#!/bin/bash
# Helper script used by puppet module ipfilter
# https://github.com/janorn/puppet-ipfilter
# Exit code from this script is a bitmap letting you now what failed.
#  1 = 001 = ipf.conf
#  2 = 010 = ipnat.conf
#  4 = 100 = ippool.conf
#
PATH=${PATH}:/usr/sbin:/usr/lib/ipf
IPFILCONF=/etc/ipf/ipf.conf
IP6FILCONF=/etc/ipf/ipf6.conf
IPNATCONF=/etc/ipf/ipnat.conf
IPPOOLCONF=/etc/ipf/ippool.conf

load_ipf() {
        bad=0
        if [ -r ${IPFILCONF} ]; then
                ipf -IFa -f ${IPFILCONF} >/dev/null
                if [ $? != 0 ]; then
                        echo "$0: load of ${IPFILCONF} into alternate set failed"
                        bad=1
                fi
        fi
        if [ -r ${IP6FILCONF} ]; then
                ipf -6IFa -f ${IP6FILCONF} >/dev/null
                if [ $? != 0 ]; then
                        echo "$0: load of ${IP6FILCONF} into alternate set failed"
                        bad=1
                fi
        fi
        if [ $bad -eq 0 ] ; then
                ipf -s -y >/dev/null
                return 0
        else
                echo "Not switching config due to load error."
                return 1
        fi
}

load_ipnat() {
        if [ -r ${IPNATCONF} ]; then
                ipnat -CF -f ${IPNATCONF} >/dev/null
                if [ $? != 0 ]; then
                        echo "$0: load of ${IPNATCONF} failed"
                        return 2
                else
                        ipf -y >/dev/null
                        return 0
                fi
        else
                return 0
        fi
}

load_ippool() {
        if [ -r ${IPPOOLCONF} ]; then
                ippool -F >/dev/null
                ippool -f ${IPPOOLCONF} >/dev/null
                if [ $? != 0 ]; then
                        echo "$0: load of ${IPPOOLCONF} failed"
                        return 4
                else
                        return 0
                fi
        else
                return 0        
        fi
}

case "$1" in
        reload)
        		load_ippool
        		err=$?
        		load_ipf
        		let "err = err + $?"
        		load_ipnat
        		let "err = err + $?"
                if [ $err = 0 ]; then
                        exit 0
                else
                		echo "Restoring previous working config"
                		for backup in /etc/ipf/ip*.conf.previous
                		do
                				conffile=$(echo $backup | sed 's/.previous//')
                				rm $conffile
                				cp $backup $conffile
                		done
                        exit $err
                fi
                ;;
                
        *)
                echo -n "Usage: $0 " >&2
                echo "reload" >&2
                exit 1
                ;;

esac

