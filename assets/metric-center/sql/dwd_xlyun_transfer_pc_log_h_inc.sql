insert overwrite table dw_xlyun.dwd_xlyun_transfer_pc_log_h_inc partition (ds = '${date}', hour = '${hour}', platform = 'pc')
select
    raw.serverinfo as server_info
    , raw.cmdid
    , raw.appid
    , raw.product_version
    , raw.extdata['partnerid'] as service_name
    , coalesce(raw.extdata['partnervesion'], raw.extdata['partnerversion']) as service_version
    , raw.peerid as peer_id
    , raw.guid
    , raw.userid as user_id
    , raw.extdata_head
    , raw.processid as process_id
    , raw.eventid as event_id
    , raw.attribute1
    , raw.attribute2
    , raw.cost1
    , raw.cost2
    , raw.cost3
    , raw.cost4
    , raw.extdata_record
    , raw.ts
    , raw.extdata
    , raw.extdata['parentid'] as parent_id
    , raw.extdata['traceid'] as seqid
    , xl_inet_ntoa(xl_htonl(cast(raw.serverinfo[1] as bigint))) as ip
    , if(raw.extdata['result'] = '99%' or raw.extdata['result'] = 'auto_restart', 'restart', raw.extdata['result']) as final_result
    , raw.extdata['type'] as mode
    , xl_urldecode(raw.extdata['filename']) as file_name
    , regexp_extract(raw.extdata['filename'], '\\\.([^.]*)$', 1) as file_suffix
    , cast(raw.extdata['filesize'] as bigint) as file_size
    , cast(raw.extdata['dcdnpeernum'] as bigint) as cdn_res_count
    , cast(raw.extdata['offlinenum'] as bigint) as dcdn_hub_res_num
    , cast(raw.extdata['highnum'] as bigint) as high_res_count
    , raw.extdata['errorcode'] as error_code
    , raw.eventid as task_type
    , if(length(raw.extdata['sgcid']) = 40, raw.extdata['sgcid'], null) as hub_gcid
    , if(length(raw.extdata['gcid']) = 40, raw.extdata['gcid'], null) as real_gcid
    , cast(raw.extdata['duration'] as bigint) as download_time
    , cast(raw.extdata['recvbytes'] as bigint) as recv_bytes
    , raw.extdata['viptype'] as vip_type
    , if(
        (coalesce(cast(raw.extdata['vip_acc_request'] as int), 0) >= 10 and coalesce(cast(raw.extdata['vip_acc_request'] as int), 0) <= 30)
        or (cast(raw.extdata['vip_dcdn_query'] as bigint) >= '10' and cast(raw.extdata['vip_dcdn_query'] as bigint) <= '30')
        or (cast(raw.extdata['dcdn_query_peer_result'] as bigint) in (65, 69, 70, 71))
        or (nvl(cast(raw.extdata['FileProperty'] as int), 0) > 0 and nvl(cast(raw.extdata['FileProperty'] as int), 0) <> 999)
        , '1', '0'
    ) as anti_server
    , raw.extdata['taskorigin'] as task_origin
    , xl_urldecode(xl_urldecode(raw.extdata['refurl'])) as ref_url
    , xl_urldecode(xl_urldecode(raw.extdata['fileurl'])) as file_url
    , if(raw.extdata['avgglobalspeedoftask'] > 0, raw.extdata['avgglobalspeedoftask'], null) as global_speed
    , cast(raw.extdata['downloadstrategy'] as bigint) as download_strategy
    , nvl(raw.extdata['vip_dcdn_token'], raw.extdata['vip_dcdn_token_backup']) as token
    , cast(if(
        nvl(raw.extdata['errorbytes'], 0) > nvl(raw.extdata['eraseddatasize'], 0)
        , nvl(raw.extdata['errorbytes'], 0)
        , nvl(raw.extdata['eraseddatasize'], 0)
    ) as bigint)as error_bytes
    , raw.extdata['indexextradata'] as index_extra_data
    , cast(raw.extdata['vip_vipspeed'] as bigint) as jiasu_vip_speed
    , cast(raw.extdata['vip_superspeed'] as bigint) as jiasu_super_speed
    , cast(raw.extdata['vip_smooth'] as bigint) as jiasu_smooth
    , cast(raw.extdata['vip_zerospeed'] as bigint) as jiasu_zero_speed
    , cast(raw.extdata['vip_group'] as bigint) as jiasu_group
    , cast(raw.extdata['recvbytes'] as bigint) as all_bytes
    , cast(raw.extdata['originbytes'] as bigint) as origin_bytes
    , cast(raw.extdata['p2sbytes'] as bigint) as server_bytes
    , cast(raw.extdata['phubbytes'] as bigint) as phub_bytes
    , cast(raw.extdata['phubnum'] as bigint) as phub_peer
    , cast(raw.extdata['trackerbytes'] as bigint) as tracker_bytes
    , cast(raw.extdata['trackernum'] as bigint) as tracker_peer
    , cast(raw.extdata['dcdnpeerbytes'] as bigint) as dcdn_bytes
    , cast(raw.extdata['dcdnpeernum'] as bigint) as dcdn_peer
    , cast(raw.extdata['pcdnpeerbytes'] as bigint) as pcdn_bytes
    , cast(raw.extdata['pcdnpeernum'] as bigint) as pcdn_peer
    , cast(raw.extdata['phubbonusbytes'] as bigint) as bonus_bytes
    , cast(raw.extdata['phubbonusnum'] as bigint) as bonus_peer
    , cast(raw.extdata['phubcdnpeerbytes'] as bigint) as phub_cdn_bytes
    , cast(raw.extdata['phubdcdnpeerbytes'] as bigint) as phub_dcdn_bytes
    , cast(raw.extdata['phubvcachebytes'] as bigint) as xphub_bytes
    , cast(raw.extdata['superpcdnpeerbytes'] as bigint) as super_pcdn_bytes
    , cast(raw.extdata['superpcdnpeernum'] as bigint) as super_pcdn_peer
    , if(raw.extdata['phubnum'] is null or raw.extdata['phubnum'] = 'NULL' or raw.extdata['phubnum'] = '0', 0, cast(raw.extdata['phubnum'] as bigint)) as phub_res_peer
    , if(raw.extdata['phubusednum'] is null or raw.extdata['phubusednum'] = 'NULL' or raw.extdata['phubusednum'] = '0', 0, cast(raw.extdata['phubusednum'] as bigint)) as phub_insert_peer
    , cast(raw.extdata['avgdownloadingtasknum'] as bigint) as running_task_count_avg
    , cast(raw.extdata['avgdownloadingmaintasknum'] as bigint) as running_user_task_count_avg
    , cast(raw.extdata['globalrecvbytes'] as bigint) as global_all_bytes
    , cast(raw.extdata['globalphubbytes'] as bigint) as global_p2p_bytes
    , cast(raw.extdata['globalp2sbytes'] as bigint) as global_p2s_bytes
    , cast(raw.extdata['globalphubbonusbytes'] as bigint) as global_bonus_bytes
    , cast(raw.extdata['globaldcdnpeerbytes'] as bigint) as global_dcdn_bytes
    , cast(raw.extdata['globaloriginalurlbytes'] as bigint) as global_origin_bytes
    , if(length(raw.extdata['originaletag']) > 0, raw.extdata['originaletag'], null) as etag
    , cast(raw.extdata['queryallhubcount'] as bigint) as query_all_hub_count
    , raw.extdata['queryallhubresult'] as query_all_hub_result
    , cast(str_to_map(raw.extdata['global_speedtarget'], ';', ':')['1'] as bigint) as global_speed_target_1
    , cast(str_to_map(raw.extdata['global_speedtarget'], ';', ':')['64'] as bigint) as global_speed_target_64
    , cast(raw.extdata['firstinsertpcdnpeertime'] as bigint) as first_insert_pcdn_peer_time
    , cast(raw.extdata['takemuchmemorycount'] as bigint) + cast(raw.extdata['takemorememorycount'] as bigint) as alloc_data_buffer_fail_count
    , cast(raw.extdata['globalspeedmaxinwindow'] as bigint) as global_speed_max_in_window
    , cast(raw.extdata['endingspantime'] as bigint) as ending_span_time
    , raw.extdata['isnetdiskfetchtask'] as is_netdisk_fetch_task
    , raw.extdata['firstvideomode'] as first_video_mode
    , '' as action_type
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
        , eventid
        , attribute1
        , attribute2
        , cost1
        , cost2
        , cost3
        , cost4
        , extdata_record
        , ts
        , if(extdata_record like '%=%', str_to_map(extdata_record, ',', '='), str_to_map(xl_urldecode(extdata_record),',','=')) as extdata --pc端上报，部分加码了，部分未加码
    from
        complat_odl.stat_event
    where
        ds = '${date}'
        and hour = '${hour}'
        and appid = '33'
        and eventid in ('4635', '4636', '4637', '4638', '4639') --任务结束上报对应的eventid
--         and attribute1 <> 'mi_check'
--         and serverinfo[1] rlike '^\\\d+$'
--         and substr(peerid, 1, 15) <> '00D8617888205XS'
) as raw
;
