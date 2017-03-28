#define N 3
#define L (2*N)
#define noMore (masters < 2)
#define StopCondition (record_slaves_num > N/2)

mtype = {occupy, free, ok, no};

chan q[N+1] = [L+2] of {mtype, byte};

byte masters = 0;
byte slaves = 0;
byte record_slaves_num = 0;
byte node_num = 0;

proctype node (byte mynumber)
{
	byte number, owner, slaves_list[N], slaves_num;
	bit master, slave;
	int i;	
Begin:
	if
	:: !StopCondition ->
		printf("MSC: %d node starts interview\n", mynumber);

		for (i : 1 .. N) {
			q[i] ! occupy(mynumber);
			printf("MSC: %d node sends request to %d node\n", mynumber, i);
		}
	:: else -> goto End;
	fi;

	end: do
	
	:: StopCondition -> break;

	:: q[mynumber] ? ok(number) ->
		atomic {
		if
                :: StopCondition -> break;
                :: else -> skip;
                fi;
 
		slaves_list[slaves_num] = number;
		slaves_num++;
		assert(slaves_num <= N);

		if
		:: (slaves_num > record_slaves_num) -> record_slaves_num = slaves_num;
		:: else -> skip;
		fi;

		printf("MSC: %d node enslaved the %d node, and now it has %d slaves\n", mynumber, number, slaves_num);
		
		if
		:: (slaves_num > N/2) ->
			master = 1;
                	masters++;
                	assert(masters <= 1);
                	printf("MSC: %d node became a master.\n Now masters: %d.\n Now slaves: %d.\n", mynumber, masters, slaves);
			break;
		:: else -> skip;
		fi; 
		}

	:: q[mynumber] ? no(number) -> skip;

	:: q[mynumber] ? occupy(number) ->
		atomic {
		if
                :: StopCondition -> break;
                :: else -> skip;
                fi;
		if
		:: (slave == 0) -> 
			slave = 1;
			owner = number;
			slaves++;
			assert(slaves <= N);
			q[number] ! ok(mynumber);
			printf("MSC: %d node enslaved by %d node\n", mynumber, number);
		:: else -> 
			q[number] ! no(mynumber);
			printf("MSC: %d node rejected the %d node\n", mynumber, number);
		fi;
		}

	:: q[mynumber] ? free(number) ->
		atomic {
		if
                :: StopCondition -> break;
                :: else -> skip;
                fi;

		if
		:: (owner == number) -> 
			owner = 0;
			slave = 0;
			printf("MSC: %d node free by %d node\n", mynumber, number);
		:: else -> skip;
		fi;
		}

	:: (!StopCondition) && (!len(q[mynumber])) && (slaves == N) ->
		atomic {
                if
                :: (slaves_num > 0) ->
	//		printf("slaves_list itoms: %d, %d, %d\n", slaves_list[0], slaves_list[1], slaves_list[2]);
                        for (i in slaves_list) {
	//			printf("%d : %d\n", i, slaves_list[i]);
				node_num = slaves_list[i];
				if 
				:: (node_num == 0) -> skip;
				:: else ->
	//				printf("MSC: node_num: %d\n", node_num);
                                	q[node_num] ! free(mynumber);
					slaves_num--;
					assert(slaves_num >= 0);
					slaves--;
					assert(slaves >= 0);
				fi;
                        }
                        printf("MSC: %d node dont became a master, all slaves free\n", mynumber);
                        goto Begin;
                :: else ->
                        goto Begin;
                fi;
		}
	od

End:
	skip;
}

init {
	byte proc = 1;
	atomic {
	do
	:: proc <= N ->
		run node(proc);
		proc++
	:: proc > N -> break
	od
	}		
}
	
never { /* !([] noMore) */
T0_init:
 	if
 	:: (! ((noMore))) -> goto accept_all
 	:: (1) -> goto T0_init
 	fi;
accept_all:
 	skip
} 
