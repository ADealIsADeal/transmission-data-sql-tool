insert overwrite table dw_xlyun.dwd_xlyun_transfer_log_h_inc partition (ds = '${date}', hour = '${hour}', platform)
select
    raw.serverinfo as server_info
    , raw.cmdid
    , raw.appid
    , raw.product_version
    , raw.service_name
    , raw.service_version
    , raw.peerid as peer_id
    , raw.guid
    , raw.userid as user_id
    , raw.extdata_head
    , raw.processid as process_id
    , raw.seqid
    , raw.eventid as event_id
    , raw.eventstatus as event_status
    , raw.extdata_record
    , raw.ts
    , raw.extdata
    , raw.extdata['UserId'] as user_id_parsed
    , raw.extdata['AppSeqId'] as parent_id
    , xl_inet_ntoa(xl_htonl(cast(raw.serverinfo[1] as bigint))) as ip
    , raw.extdata['Status'] as final_result
    , if(raw.extdata['TaskType'] = '9', 'new', raw.extdata['Mode']) as mode
    , xl_urldecode(raw.extdata['Filename']) as file_name
    , regexp_extract(raw.extdata['Filename'], '\\\.([^.]*)$', 1) as file_suffix
    , cast(raw.extdata['FileSize'] as bigint) as file_size
    , cast(raw.extdata['CDNResCount'] as bigint) as cdn_res_count
    , cast(raw.extdata['DcdnHubResNum'] as bigint) as dcdn_hub_res_num
    , cast(raw.extdata['HighResCount'] as bigint) as high_res_count
    , raw.extdata['ErrorCode'] as error_code
    , raw.extdata['TaskType'] as task_type
    , raw.extdata['HubGcid'] as hub_gcid
    , raw.extdata['RealGcid'] as real_gcid
    , cast(raw.extdata['Seconds'] as bigint) as download_time
    , cast(raw.extdata['RecvBytes'] as bigint) as recv_bytes
    , raw.extdata['VipType'] as vip_type
    , case
        when raw.extdata['FileProperty'] in ('0', '999') then '0'
        when raw.extdata['FileProperty'] is not null then '1'
        when raw.extdata['OfflineTaskRequetErrorCode'] in ('75', '76')
            or raw.extdata['OfflineBtTaskRequetErrorCode'] in ('75', '76')
            or raw.extdata['HighSpeedTaskBillingErrorCode '] in ('508', '509')
            or (nvl(raw.extdata['VipDcdnQuerySwitch'], '0') != '1' and (raw.extdata['DcdnQueryResult'] = '14' or cast(raw.extdata['DcdnQueryReturnCode'] as int) in (66, 70, 71, 72)))
            or (raw.extdata['VipDcdnQuerySwitch'] = '1' and cast(raw.extdata['DcdnQueryResult'] as int) >= 11 and cast(raw.extdata['DcdnQueryResult'] as int) <= 31) then '1'
        else '0'
    end as anti_server
    , concat(concat(split(xl_urldecode(raw.extdata['TaskOrigin']), '/')[0], '/'), split(xl_urldecode(raw.extdata['TaskOrigin']), '/')[1]) as task_origin
    , xl_urldecode(xl_urldecode(raw.extdata['RefUrl'])) as ref_url
    , xl_urldecode(xl_urldecode(raw.extdata['Url'])) as file_url
    , if(raw.extdata['AllTaskDownloadSpeedAvg'] > 0, raw.extdata['AllTaskDownloadSpeedAvg'], null) as global_speed
    , cast(raw.extdata['DownloadStrategy'] as bigint) as download_strategy
    , if(length(raw.extdata['AccTokenPayload']) > 8, raw.extdata['AccTokenPayload'], null) as token
    , cast(raw.extdata['CheckErrorBytes'] as bigint) as error_bytes
    , raw.extdata['IndexExtraData'] as index_extra_data
    , cast(raw.extdata['vip_vipspeed'] as bigint) as jiasu_vip_speed
    , cast(raw.extdata['vip_superspeed'] as bigint) as jiasu_super_speed
    , cast(raw.extdata['vip_smooth'] as bigint) as jiasu_smooth
    , cast(raw.extdata['vip_zerospeed'] as bigint) as jiasu_zero_speed
    , cast(raw.extdata['vip_group'] as bigint) as jiasu_group
    , cast(raw.extdata['RecvBytes'] as bigint) as all_bytes
    , cast(raw.extdata['OrigionBytes'] as bigint) as origin_bytes
    , cast(raw.extdata['ServerBytes'] as bigint) as server_bytes
    , cast(raw.extdata['PhubBytes'] as bigint) as phub_bytes
    , cast(raw.extdata['PhubResCount'] as bigint) as phub_peer
    , cast(raw.extdata['TrackerBytes'] as bigint) as tracker_bytes
    , cast(raw.extdata['TrackerResCount'] as bigint) as tracker_peer
    , cast(raw.extdata['DcdnDownloadBytes'] as bigint) as dcdn_bytes
    , cast(raw.extdata['DcdnResNum'] as bigint) as dcdn_peer
    , cast(raw.extdata['PcdnPeerBytes'] as bigint) as pcdn_bytes
    , cast(raw.extdata['PcdnResNum'] as bigint) as pcdn_peer
    , cast(raw.extdata['BonusBytes'] as bigint) as bonus_bytes
    , cast(raw.extdata['BonusResCount'] as bigint) as bonus_peer
    , cast(raw.extdata['PHubCDNBytes'] as bigint) as phub_cdn_bytes
    , cast(raw.extdata['PHubDCDNBytes'] as bigint) as phub_dcdn_bytes
    , cast(raw.extdata['PartialBytes'] as bigint) as xphub_bytes
    , cast(raw.extdata['SuperPcdnPeerBytes'] as bigint) as super_pcdn_bytes
    , cast(raw.extdata['SuperPcdnResNum'] as bigint) as super_pcdn_peer
    , cast(raw.extdata['PhubResCount'] as bigint) as phub_res_peer
    , cast(raw.extdata['PhubInsertedRes'] as bigint) as phub_insert_peer
    , cast(raw.extdata['RunningTaskCountAvg'] as bigint) as running_task_count_avg
    , cast(raw.extdata['RunningUserTaskCountAvg'] as bigint) as running_user_task_count_avg
    , cast(raw.extdata['AllTaskRecvBytes'] as bigint) as global_all_bytes
    , cast(raw.extdata['AllTaskPhubBytes'] as bigint) as global_p2p_bytes
    , cast(raw.extdata['AllTaskServerBytes'] as bigint) as global_p2s_bytes
    , cast(raw.extdata['AllTaskBonusBytes'] as bigint) as global_bonus_bytes
    , cast(raw.extdata['AllTaskDcdnDownloadBytes'] as bigint) as global_dcdn_bytes
    , cast(raw.extdata['AllTaskOriginBytes'] as bigint) as global_origin_bytes
    , cast(raw.extdata['DcdnHasQuery'] as bigint) as query_all_hub_count
    , raw.extdata['DcdnQueryReturnCode'] as query_all_hub_result
    , cast(split(str_to_map(xl_urldecode(extdata['LevelStrategy']), ';', '\\|')['1'], '-')[0]  as bigint) as global_speed_target_1
    , cast(split(str_to_map(xl_urldecode(extdata['LevelStrategy']), ';', '\\|')['64'], '-')[0] as bigint) as global_speed_target_64
    , cast(raw.extdata['PcdnResFirstInsertTime'] as bigint) as first_insert_pcdn_peer_time
    , cast(raw.extdata['MaxGlobalDownloadSpeed'] as bigint) as global_speed_max_in_window
    , cast(raw.extdata['AllocDataBufferFailCount'] as bigint) as alloc_data_buffer_fail_count
    , cast(raw.extdata['TaskFinishCostMs'] as bigint) as ending_span_time
    , raw.extdata['PlayerMode'] as player_mode
    , '' as action_type
    , raw.platform
from (
    select
        serverinfo
        , cmdid
        , appid
        , product_version
        , service_name
        , service_version
        , peerid
        , guid
        , userid
        , extdata_head
        , processid
        , seqid
        , eventid
        , eventstatus
        , extdata_record
        , ts
        , str_to_map(extdata_record, ',', '=') as extdata
        , case
            when appid = '18' and service_name = '6009' then 'android'
            when appid = '19' and service_name = '6050' then 'ios'
            when appid = '19' and service_name = '6015' then 'mac'
            when appid = '18' and service_name in ('6057', '6062', '6067', '6066') then 'nas'
            when appid = '18' and service_name in ('6100', '6135', '6136') then 'harmony'
            else 'other' end as platform
    from
        complat_odl.stat_heartbeat
    where
        ds = '${date}'
        and hour = '${hour}'
        and eventstatus = '2'   --任务状态，0：创建，2:完成（任务结束状态，包含成功和失败）
        and appid in ('18', '19')
        and service_name <> '6001' --剔除小米下载
        and eventid in ('10001','10100','10101','10103','10102','10104') --任务事件id
) as raw
;
