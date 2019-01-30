/* Formatted on 1/30/2019 11:58:14 AM (QP5 v5.227.12220.39754) */
  SELECT CUSTOMER_ID,
         AA.FULL_NAME,
         AA.ADDRESS,
         AA.MIN_LOAD,
         AA.MAX_LOAD,
         (SELECT LISTAGG (bb.CUSTOMER_ID, '$')
                    WITHIN GROUP (ORDER BY aa.CUSTOMER_ID ASC)
            FROM MVIEW_CUSTOMER_INFO bb
           WHERE bb.PARENT_CONNECTION = aa.CUSTOMER_ID)
            sub_cust,
         (SELECT LISTAGG (getburner (bb.CUSTOMER_ID), '$')
                    WITHIN GROUP (ORDER BY aa.CUSTOMER_ID ASC)
            FROM MVIEW_CUSTOMER_INFO bb
           WHERE bb.PARENT_CONNECTION = aa.CUSTOMER_ID)
            sub_burner,
         (SELECT LISTAGG (bb.ADDRESS, '$')
                    WITHIN GROUP (ORDER BY aa.CUSTOMER_ID ASC)
            FROM MVIEW_CUSTOMER_INFO bb
           WHERE bb.PARENT_CONNECTION = aa.CUSTOMER_ID)
            sub_address,
         (SELECT LISTAGG (cm.METER_SL_NO, ', ')
                    WITHIN GROUP (ORDER BY aa.CUSTOMER_ID ASC)
            FROM CUSTOMER_METER cm
           WHERE cm.CUSTOMER_ID = aa.customer_id AND status <> 0)
            meter_info
    FROM MVIEW_CUSTOMER_INFO aa
   WHERE HAS_SUB_CONNECTION = 'Y' AND AA.AREA_ID = '01'
ORDER BY CUSTOMER_ID;