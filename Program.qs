namespace CounterFeitCoinAlgorithm {

    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Measurement;

    operation CFC_Pre_Reference (query : Qubit[],answer: Qubit) : Unit { 
        let n = Length(query);       
        ApplyToEach(H, query);
        for(i in 0 .. n-1){
            CNOT(query[i],answer);
        }

        // let res = ( M(answer) == Zero);
        // Message($"{res}");
    }

    operation CFC_StatePrep_Reference (query : Qubit[], answer : Qubit) : Unit
    is Adj {     
        X(answer);   
        // ApplyToEachA(H, query);
        H(answer);
    }
    

    operation CFC_UF(x : Qubit[], Coins:Int[], y : Qubit) : Unit is Adj+Ctl {
        // whenever meets a 1, use Controlled X gate
        for (i in 0 .. Length(Coins) - 1) {
            if(Coins[i] == 1){
                CNOT(x[i],y);
            }
        }
    }

    operation B_oracle(query:Int[]): Bool {
        using(qs = Qubit[Length(query)]){
            mutable result = 0;
            ApplyToEach(X, qs);
            for(i in 0 .. 2 .. Length(qs) - 1){
                Z(qs[i]);
            }

            for(i in 0 .. Length(qs) - 1){
                if(M(qs[i]) == One){
                    set result += query[i] * 1;
                }else{
                    set result += query[i] * (-1);
                }
            }

            ResetAll(qs);
            return (result == 0);
        }              
    }


    operation CounterFeitCoinGame(Coins : Int[]):Int[]{
         using ((register, output) = (Qubit[Length(Coins)], Qubit())) {
                mutable correct = false;
                // prepare qubits in the right state
                repeat {
                CFC_Pre_Reference(register,output);
                let res = M(output);
                // Check whether the result is correct
                if (res == Zero) {
                    set correct = true;
                }else{
                    ApplyToEach(H, register);
                }  
                //repeat until we observe a 0 state
                } until (correct);
                CFC_StatePrep_Reference(register, output);
            
                // apply oracle
                CFC_UF(register, Coins, output);
            
                // apply Hadamard to each qubit of the input register
                ApplyToEach(H, register);
            
                mutable answer = new Bool[Length(Coins)];
                // measure all qubits of the input register;
                // the result of each measurement is converted to an Int
                let tmp = MultiM(register);
                mutable numberOfFakeCoins = 0;
                set answer = ResultArrayAsBoolArray(tmp);
                for (i in 0 .. Length(answer) - 1) {
                    if (answer[i]) {
                        set numberOfFakeCoins += 1;
                    }
                }

                //output the position of the counterfeit coins
                mutable result = new Int[numberOfFakeCoins];
                mutable num = 0;
                for (i in 0 .. Length(answer) - 1) {
                    if (answer[i]) {
                        set result w/=num <-  i;
                        set num += 1;
                    }
                }

                //in case we find the fair coins
                mutable newResult = new Int[Length(Coins) - numberOfFakeCoins];
                mutable num2 = 0;
                if(Coins[result[0]] == 0){
                    for(i in 0 .. Length(Coins)-1){
                        if (not isContained(result,i)) {
                            set newResult w/= num2 <- i;
                            set num2 += 1;
                        }
                    }
                    set result = new Int[Length(Coins) - numberOfFakeCoins];
                    for(j in 0 .. Length(result)-1){
                        set result w/= j <- newResult[j];
                    }
                }

                // mutable fairCoins = new Int[Length(Coins) - numberOfFakeCoins];
                // mutable index = 0;
                // for(i in 0 .. (Length(result)-1)){
                //     if(not isContained(result,i)){
                //         set fairCoins w/=index <- Coins[i];
                //         set index+=1;
                //     }
                // }

                // before releasing the qubits make sure they are all in |0⟩ state 
                Reset(output);
                ResetAll(register);


                // if(not B_oracle(fairCoins)){
                //     set result = new Int[0];
                // }
                //return the position of the fake coin
                return result;
            }
       
    }

    operation isContained(numbers:Int[], index:Int): Bool{
        for(i in 0 .. Length(numbers) - 1){
            if(numbers[i] == index){
                return true;
            }
        }

        return false;
    }

    operation CounterfeitCoin_Main () : Int[] {
        let res = CounterFeitCoinGame([0,0,0,1,0,1,1,0,0,0]);
        return res;
    }
    // operation balanceScale (left: Qubit[],right:Qubit[]) : Bool {
    //     let len = Length(left);
    //     mutable register = new Int[len*2];
    //     set register += left;
    //     set register += right;
    //     mutable res = 0;
    //     let N = Length(register);
    //     for(i in 0 .. N-1){
    //         mutable tmp = 0;
    //         if(M(register[i]) == One){
    //             set tmp = 1;
    //         }
    //         if(i % 2 == 0){
    //             set res = res + tmp * 1;
    //         }else{
    //             set res = res + tmp * (-1);
    //         }
    //     }
    //     return (res == 0);
    // }

    // operation check (fakeSets:Int[], fairSets:Int[]) : Bool {
    //    //1.Divide X1 into k+1 equal-sized subsets Y1,Y2,...,Yk+1 (recall the above assumption).
    //    let k = Length(fakeSets);
    //    let N = Length(fairSets);
    //    mutable tmpSets = new Int[][k+1];
    //    for(i in 0 .. k){
    //        mutable row = new Int[N/k+1];
    //        for(j in 0 .. (N/k+1)-1){
    //            set row w/=j <- fairSets[k*i + j];
    //        }
    //        set tmpSets w/= i <- row;
    //    }


    // //2 LetL=Y1 and R=Y2.For i=1 to log(k+1),repeat Steps2.1–2.2.
    //    for(i in 1 .. Log(IntAsDouble(k+1))){
    //        mutable L = new Int[(N/k+1) * PowI(2,number)];
    //        if(i == 1){
    //            set L = tmpSets[0];
    //        }else{
    //            set L = checkHelper2(L,R);
    //        }
    //        mutable R = checkHelper(tmpSets,i);

    //        if(not balanceScale(L,R)){
    //            return false;
    //        }
    //    }

    //     //3. Output YES.
    //     return true;
    // }

    // operation checkHelper(tmpSets: Int[][], number: Int):Int[]{
    //      mutable R = new Int[(N/k+1) * PowI(2,number)];
    //      for(i in PowI(2,number) .. Pow(2,number+1)-1){
    //         set R+= tmpSets[i];
    //      }
    //      return R;
    // }

    // operation checkHelper2(left: Int[], right: Int[]):Int[]{
    //     let length = Length(left);
    //     mutable tmp = new Int[2*length];
    //     set tmp+= left;
    //     set tmp+= right;
    //     return tmp;
    // }


    // operation Impl (registerS: Qubit[],targetR:Qubit) : Unit {
    //     //1.1 Prepare√1 (|0⟩+|1⟩)in a register R.
    //     H(targetR);

    //     //1.2 If the content of R is 1,flip all the N bits in S.
    //     for(i in 0 .. Length(registerS)-1){
    //         CNOT(targetR,registerS[i]);
    //     }

    //     //1.3 If the content of S is not in S+ , flip the bit in R.
    //     for(i in 0 .. Length(registerS)-1){
    //         if(i % 2 == 0){
    //             if(M(targetR) == One){
    //                 X(targetR);
    //             }  
    //         }
    //     }

    //     //2
    //     ApplyToEachA(H,registerS);
    // }

    // operation findK (Coin: Int[],k:Int) : Unit {
    //     //1. Prepare N qubits |0⟩⊗N in a register R, and apply a unitary transformation W of Lemma 1 to them. 
    //     using ((x, y) = (Qubit[Length(Coins)], Qubit())) {
    //         Impl(x,y);
    //     }




    //     //3. Apply W −1 to the state in R. By Lemma 1, we obtain the final state
    //     Adjoint Impl(x,y);

    //     //Then measure R in the computational basis
    //     let res = MultiM(register);
    //     mutable answer = new Bool[Length(Coins)];
    //     set answer = ResultArrayAsBoolArray(res);
    //     mutable fakeSets = new Int[k];
    //     mutable fairSets = new Int[Length(coins) - k];

    //     for(i in 0 .. Length(answer)-1){
    //         if(answer[i] == true){
    //             set fakeSets += answer[i];
    //         }else{
    //             set fairSets += answer[i];
    //         }
    //     }

    //     if(check(fakeSets,fairSets)){
    //         Message($"{answer}");
    //     }

    // }
    

    operation HelloQ() : Unit {
        Message("Hello quantum world!");
    }
}

