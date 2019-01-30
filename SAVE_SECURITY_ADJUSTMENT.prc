CREATE OR REPLACE PROCEDURE JALALABAD.Save_Security_Adjustment(
   iCustomerId         IN   VARCHAR2,
   iIsmeter            IN   VARCHAR2,
   iSecurityAmount     IN   NUMBER,
      
   iAdjustmentMode     IN   VARCHAR2,
   iTotalAdjustAmount  IN   NUMBER,
   iComment            IN   VARCHAR2,
      
   iCollectionDate     IN   VARCHAR2,  
   iBillIdArr          IN   VARCHARARRAY,
   iAdjustAmountArr    IN    NUMBERARRAY,
   
   iSurchargeAmountArr IN    NUMBERARRAY,   
   iUserId             IN   VARCHAR2,    
   
   oResponse          OUT  NUMBER,
   oRespMsg           OUT  VARCHAR2
)

IS  
tDeposit_id     NUMBER := SQN_DEPOSIT.nextval;
tstatus number ;
tdueAmount number;
  

BEGIN
   oResponse := 0;
   
    If(iAdjustmentMode='1') Then      
      
      insert into mst_deposit (
        DEPOSIT_ID,CUSTOMER_ID,TOTAL_DEPOSIT,DEPOSIT_DATE,DEPOSIT_PURPOSE,DEPOSIT_TYPE,INSERTED_ON,INSERTED_BY,STATUS,REMARKS, BANK_ID,BRANCH_ID ,ACCOUNT_NO)
        Values
        (tDeposit_id,iCustomerId,-iTotalAdjustAmount,to_date(iCollectionDate,'DD-MM-YYYY'),2,0, sysdate,iUserId ,1,iComment,'S12345','S1234501','S123450101');
        
        
      insert into SECURITY_ADJUSTMENT (
        CUSTOMER_ID,DEDUCED_AMOUNT,COLLECTION_DATE, INSERTED_BY,STATUS,REMARKS,DEPOSIT_ID)
        Values
       (iCustomerId,iTotalAdjustAmount,to_date(iCollectionDate,'DD-MM-YYYY'),iUserId ,'R',iComment,tDeposit_id);
     
     oRespMsg:='Refunded Successfully.';  
       
   ELSIF (iAdjustmentMode='2') Then
   
    FOR i IN 1 .. iBillIdArr.COUNT
           LOOP
           
           SELECT due_amount
                INTO tdueAmount
              FROM (SELECT BILLED_AMOUNT-nvl(COLLECTED_AMOUNT,0)-nvl(COLLECTED_SURCHARGE,0) as due_amount
                      FROM bill_metered
                     WHERE bill_id = iBillIdArr(i)
                    UNION
                    SELECT BILLED_AMOUNT- nvl(COLLECTED_BILLED_AMOUNT,0) as due_amount
                      FROM bill_non_metered
                     WHERE bill_id = iBillIdArr(i));
                     
           if (tdueAmount=iAdjustAmountArr(i)) then
           tstatus:=2;
           else
           tstatus:=1;
           end if;
                    
           
           insert into SECURITY_ADJUSTMENT (
           CUSTOMER_ID,DEDUCED_AMOUNT,BILL_ID,COLLECTION_DATE, INSERTED_BY,STATUS,REMARKS,DEPOSIT_ID)
           Values
           (iCustomerId,(iAdjustAmountArr(i)+iSurchargeAmountArr(i)),iBillIdArr(i),to_date(iCollectionDate,'DD-MM-YYYY'),iUserId ,'A',iComment,tDeposit_id);
           
           insert into mst_deposit (
           DEPOSIT_ID,CUSTOMER_ID,TOTAL_DEPOSIT,DEPOSIT_DATE,DEPOSIT_PURPOSE,DEPOSIT_TYPE,INSERTED_ON,INSERTED_BY,STATUS,REMARKS,BANK_ID,BRANCH_ID ,ACCOUNT_NO)
           Values
           (tDeposit_id,iCustomerId,-(iAdjustAmountArr(i)+iSurchargeAmountArr(i)),to_date(iCollectionDate,'DD-MM-YYYY'),2,0, sysdate,iUserId ,1,iComment,'S12345','S1234501','S123450101');
           
           if(iIsmeter='Metered') then
           
            Update BILL_METERED Set Status=tstatus,Collected_amount=nvl(COLLECTED_AMOUNT,0)+iAdjustAmountArr(i),COLLECTED_SURCHARGE=nvl(COLLECTED_SURCHARGE,0)+iSurchargeAmountArr(i),COLLECTION_DATE=to_date(iCollectionDate,'dd-MM-YYYY'),BRANCH_ID='S1234501'  Where Bill_Id=iBillIdArr(i);
           
            INSERT INTO
            BILL_COLLECTION_METERED (COLLECTION_ID, CUSTOMER_ID, BILL_ID, BANK_ID, BRANCH_ID, ACCOUNT_NO, COLLECTION_DATE, TAX_AMOUNT, COLLECTION_AMOUNT, REMARKS, COLLECED_BY, INSERTED_ON, PAYABLE_AMOUNT) 
            VALUES
            (SQN_COLLECTION_M.NEXTVAL,iCustomerId, iBillIdArr(i),'S12345','S1234501','S123450101',to_date(iCollectionDate,'DD-MM-YYYY'),0,iAdjustAmountArr(i)+iSurchargeAmountArr(i),iComment,iUserId,sysdate,iAdjustAmountArr(i)+iSurchargeAmountArr(i) );
            
            else
            
            UPDATE BILL_NON_METERED set COLLECTED_BILLED_AMOUNT=nvl(COLLECTED_BILLED_AMOUNT,0)+iAdjustAmountArr(i),COLLECTED_PAYABLE_AMOUNT=nvl(COLLECTED_PAYABLE_AMOUNT,0)+iAdjustAmountArr(i)+iSurchargeAmountArr(i),COLLECTED_SURCHARGE= nvl(COLLECTED_SURCHARGE,0)+iSurchargeAmountArr(i),COLLECTION_DATE=to_date(iCollectionDate,'dd-MM-YYYY'),BRANCH_ID='S1234501',STATUS=tstatus
            where BILL_ID= iBillIdArr(i);
            
            INSERT INTO BILL_COLLECTION_NON_METERED (COLLECTION_ID, CUSTOMER_ID, BILL_ID, BANK_ID, BRANCH_ID, ACCOUNT_NO, COLLECTION_DATE, COLLECTED_BILL_AMOUNT, COLLECTED_SURCHARGE_AMOUNT, TOTAL_COLLECTED_AMOUNT, REMARKS, COLLECED_BY, INSERTED_ON)
            values
            (SQN_COLLECTION_NM.NEXTVAL,iCustomerId,iBillIdArr(i),'S12345','S1234501','S123450101',to_date(iCollectionDate,'DD-MM-YYYY'),iAdjustAmountArr(i),iSurchargeAmountArr(i),iAdjustAmountArr(i)+iSurchargeAmountArr(i),iComment,iUserId,sysdate  );
                   
           end if;
           
           END LOOP;                
     oRespMsg:='Bill adjusted Successfully.';
               
   End If;
   
   
   
  
   oResponse:=1;
  
   
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    oResponse:=500;      
    oRespMsg:='Exception Occured : '|| 'Error Code : '||SQLCODE|| ', Error Message : ' || SUBSTR(SQLERRM, 1, 400);
     

END Save_Security_Adjustment;
/