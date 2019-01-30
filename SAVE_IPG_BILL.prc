CREATE OR REPLACE PROCEDURE JALALABAD.Save_IPG_Bill (
   iTRANSACTION_ID            IN     VARCHAR2,
   iIPG_TRANSACTION_ID        IN     VARCHAR2,
   iTRANSACTION_STATUS_MSG    IN     VARCHAR2,
   iERROR_MESSAGE             IN     VARCHAR2,
   iCARD_NO                   IN     VARCHAR2,
   iCARD_NAME                 IN     VARCHAR2,
   iTRANSACTION_STATUS_CODE   IN     VARCHAR2,
   oResponse                     OUT NUMBER,
   oRespMsg                      OUT VARCHAR2)          -- ipg_mst 200,201,444
IS
   vCUSTOMER_ID      VARCHAR2 (15);
   vISMETERED        NUMBER;
   vPAYMENT_METHOD   VARCHAR2 (15);
   --vBILL_ID                Varchar2(18);
   --vBILL_AMOUNT            number;
   --vSURCHARGE_AMOUNT       number;
   --vTOTAL_AMOUNT           number;

   vBankId           VARCHAR2 (8);
   vBranchId         VARCHAR2 (10);
   vCollectionId     NUMBER;                                             --sqn

   tErrorLog         CLOB;
   vMeterRent        NUMBER;
BEGIN
   BEGIN
      INSERT INTO IPG_RESPONSE (TRANSACTION_ID,
                                IPG_TRANSACTION_ID,
                                STATUS,
                                ERROR_MESSAGE,
                                CARD_NO,
                                CARD_NAME)
           VALUES (iTRANSACTION_ID,
                   iIPG_TRANSACTION_ID,
                   iTRANSACTION_STATUS_MSG,
                   iERROR_MESSAGE,
                   iCARD_NO,
                   iCARD_NAME);
   END;

   BEGIN
      UPDATE IPG_MST
         SET STATUS = iTRANSACTION_STATUS_CODE
       WHERE TRANSACTION_ID = iTRANSACTION_ID;
   END;

   BEGIN
      SELECT id.CUSTOMER_ID, PAYMENT_METHOD
        INTO vCUSTOMER_ID, vPAYMENT_METHOD
        FROM ipg_dtl id, ipg_mst im
       WHERE     ID.TRANSACTION_ID = IM.TRANSACTION_ID
             AND id.TRANSACTION_ID = iTRANSACTION_ID;
   END;

   BEGIN
      SELECT ISMETERED
        INTO vISMETERED
        FROM MVIEW_CUSTOMER_INFO
       WHERE CUSTOMER_ID = vCUSTOMER_ID;
   END;



   BEGIN
      SELECT bi.BANK_ID, BRANCH_ID
        INTO vBankId, vBranchId
        FROM MST_BANK_INFO bi, MST_BRANCH_INFO br
       WHERE BI.BANK_ID = BR.BANK_ID AND BANK_NAME = vPAYMENT_METHOD;
   END;


   FOR selectedBill
      IN (SELECT id.CUSTOMER_ID,
                 BILL_ID,
                 BILL_AMOUNT,
                 SURCHARGE_AMOUNT,
                 id.TOTAL_AMOUNT,
                 PAYMENT_METHOD
            FROM ipg_dtl id, ipg_mst im
           WHERE     ID.TRANSACTION_ID = IM.TRANSACTION_ID
                 AND im.TRANSACTION_ID = iTRANSACTION_ID
                 AND IM.STATUS = 200)
   LOOP
      IF (vISMETERED = 0)
      THEN
         --UPDATE BILL_NON_METERED
         --  SET status = 2
         -- WHERE BILL_ID = selectedBill.BILL_ID;
         --bindu
         UPDATE BILL_NON_METERED
            SET COLLECTED_BILLED_AMOUNT = selectedBill.BILL_AMOUNT,
                COLLECTED_PAYABLE_AMOUNT = selectedBill.TOTAL_AMOUNT,
                ACTUAL_PAYABLE_AMOUNT=selectedBill.TOTAL_AMOUNT,
                COLLECTED_SURCHARGE = selectedBill.SURCHARGE_AMOUNT,
                COLLECTION_DATE = SYSDATE,
                BRANCH_ID = vBranchId,
                STATUS = 2
          WHERE BILL_ID = selectedBill.BILL_ID;



         SELECT SQN_COLLECTION_NM.NEXTVAL INTO vCollectionId FROM DUAL;


         INSERT INTO BILL_COLLECTION_NON_METERED (COLLECTION_ID,
                                                  CUSTOMER_ID,
                                                  BILL_ID,
                                                  BANK_ID,
                                                  BRANCH_ID,
                                                  ACCOUNT_NO,
                                                  COLLECTION_DATE,
                                                  COLLECTED_BILL_AMOUNT,
                                                  COLLECTED_SURCHARGE_AMOUNT,
                                                  TOTAL_COLLECTED_AMOUNT,
                                                  REMARKS,
                                                  COLLECED_BY,
                                                  INSERTED_ON,
                                                  SURCHARGE_PER_COLL)
              VALUES (vCollectionId,
                      selectedBill.CUSTOMER_ID,
                      selectedBill.BILL_ID,
                      vBankId,
                      vBranchId,
                      vBranchId,
                      SYSDATE,
                      selectedBill.BILL_AMOUNT,
                      selectedBill.SURCHARGE_AMOUNT,
                      selectedBill.TOTAL_AMOUNT,
                      'Card Payment',
                      'System',
                      SYSDATE,
                      NULL);
      --return;

      ELSE
         -- UPDATE BILL_METERED
         --   SET status = 2
         --  WHERE BILL_ID = selectedBill.BILL_ID;
         --bindu
         SELECT METER_RENT
           INTO vMeterRent
           FROM bill_metered
          WHERE bill_id = selectedBill.BILL_ID;

         UPDATE BILL_METERED
            SET Status = 2,
                Collected_amount = selectedBill.BILL_AMOUNT,
                COLLECTED_SURCHARGE = selectedBill.SURCHARGE_AMOUNT,SURCHARGE_AMOUNT=selectedBill.SURCHARGE_AMOUNT,
                COLLECTION_DATE = SYSDATE,
                BRANCH_ID = vBranchId
          WHERE Bill_Id = selectedBill.BILL_ID;


         /*
          INSERT INTO BILL_COLLECTION_METERED (COLLECTION_ID, CUSTOMER_ID, BILL_ID, BANK_ID, BRANCH_ID, ACCOUNT_NO,
                 COLLECTION_DATE, PAYABLE_AMOUNT,TAX_AMOUNT, COLLECTION_AMOUNT, REMARKS,
                 COLLECED_BY, INSERTED_ON, CHALAN_NO,CHALAN_DATE)

          VALUES ( vCollectionId,selectedBill.CUSTOMER_ID, selectedBill.BILL_ID,vBankId, vBranchId, vBranchId,
               sysdate, selectedBill.BILL_AMOUNT, null, selectedBill.TOTAL_AMOUNT, 'Card Payment',
               'System',sysdate, null, null );
     */
         --Return;

         SELECT SQN_COLLECTION_M.NEXTVAL INTO vCollectionId FROM DUAL;

         INSERT INTO BILL_COLLECTION_METERED (COLLECTION_ID,
                                              CUSTOMER_ID,
                                              BILL_ID,
                                              BANK_ID,
                                              BRANCH_ID,
                                              ACCOUNT_NO,
                                              COLLECTION_DATE,
                                              TAX_AMOUNT,
                                              COLLECTION_AMOUNT,
                                              REMARKS,
                                              COLLECED_BY,
                                              INSERTED_ON,
                                              PAYABLE_AMOUNT,
                                              CHALAN_NO,
                                              CHALAN_DATE)
              VALUES (vCollectionId,
                      selectedBill.CUSTOMER_ID,
                      selectedBill.BILL_ID,
                      vBankId,
                      vBranchId,
                      vBranchId,
                      SYSDATE,
                      0,
                      selectedBill.TOTAL_AMOUNT,
                      'by IPG',
                      'IPG',
                      SYSDATE,
                      selectedBill.TOTAL_AMOUNT,
                      NULL,
                      NULL);
      END IF;


      --select MON into vMon from MST_MONTH where  M_ID=rec.BILL_MONTH;
      /*
      INSERT INTO BANK_ACCOUNT_LEDGER (TRANS_ID, TRANS_DATE, TRANS_TYPE, PARTICULARS, BANK_ID, BRANCH_ID,
                                      ACCOUNT_NO, DEBIT, CREDIT, BALANCE, REF_ID, INSERTED_ON, INSERTED_BY,
                                      CUSTOMER_ID, STATUS, METER_RENT, SURCHARGE, ACTUAL_REVENUE, MISCELLANEOUS)

                              VALUES ( SQN_BAL.nextval, sysdate, 1,'By Bank '||substr(selectedBill.BILL_ID,5,2)||' '||substr(selectedBill.BILL_ID,1,4), vBankId, vBranchId,
                                      vBranchId, selectedBill.TOTAL_AMOUNT, 0,0, vCollectionId, sysdate,'System',
                                      selectedBill.CUSTOMER_ID, 0,0, selectedBill.SURCHARGE_AMOUNT, selectedBill.BILL_AMOUNT,0 );
  */

      INSERT INTO BANK_ACCOUNT_LEDGER (TRANS_ID,
                                       TRANS_DATE,
                                       TRANS_TYPE,
                                       PARTICULARS,
                                       BANK_ID,
                                       BRANCH_ID,
                                       ACCOUNT_NO,
                                       DEBIT,
                                       CREDIT,
                                       BALANCE,
                                       REF_ID,
                                       INSERTED_ON,
                                       INSERTED_BY,
                                       CUSTOMER_ID,
                                       STATUS,
                                       METER_RENT,
                                       SURCHARGE,
                                       ACTUAL_REVENUE,
                                       MISCELLANEOUS)
           VALUES (SQN_BAL.NEXTVAL,
                   TO_DATE (SYSDATE, 'DD-MM-RRRR'),
                   1,
                   'By IPG',
                   vBankId,
                   vBranchId,
                   vBranchId,
                   selectedBill.TOTAL_AMOUNT,
                   0,
                   0,
                   vCollectionId,
                   SYSDATE,
                   'IPG',
                   selectedBill.CUSTOMER_ID,
                   1,
                   vMeterRent,
                   selectedBill.SURCHARGE_AMOUNT,
                   selectedBill.BILL_AMOUNT,
                   0);
   END LOOP;

   oResponse := 1;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      oResponse := 500;
      oRespMsg :=
            'Exception Occured : '
         || 'Error Code : '
         || SQLCODE
         || ', Error Message : '
         || SUBSTR (SQLERRM, 1, 400);
END Save_IPG_Bill;
/