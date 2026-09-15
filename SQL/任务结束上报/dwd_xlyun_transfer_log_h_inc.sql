------------------------------------------------------------
--  FILE:    dwd_xlyun_transfer_log_h_inc.sql
--  DESC:    传输库移动端/多端心跳日志 DWD（小时增量，字段下沉解析，不去重）
--  CHANGE:  20260701 时效切换小时；extdata 业务字段在 DWD 解析
--           移动端补充 first_insert_pcdn_peer_time/global_speed_max_in_window
--           鸿蒙扩充 service_name: 6100/6135/6136
--  PARAM:   ds='${date}', hour='${hour}'
------------------------------------------------------------

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

-- create table dw_xlyun.dwd_xlyun_transfer_log_h_inc (
--     server_info             array<string> comment 'serverinfo'
--     , cmdid                 bigint comment '命令id'
--     , appid                 string comment '产品id'
--     , product_version       string comment '下载库版本号'
--     , service_name          string comment '服务名'
--     , service_version       string comment '上层版本号'
--     , peer_id               string comment 'peerid'
--     , guid                  string comment '设备id'
--     , user_id               string comment '用户id原始字段'
--     , extdata_head          string comment ''
--     , process_id            string comment '进程识别号'
--     , seqid                 bigint comment '分片id'
--     , event_id              string comment '事件id'
--     , event_status          bigint comment '任务状态'
--     , extdata_record        string comment '原始扩展字段'
--     , ts                    bigint comment '上报时间'
--     , extdata               map<string, string> comment '拓展字段map'
--     , user_id_parsed        string comment '解析后用户id'
--     , parent_id             string comment '主任务id'
--     , ip                    string comment '客户端ip'
--     , final_result          string comment '下载结果'
--     , mode                  string comment '续传类型'
--     , file_name             string comment '文件名'
--     , file_suffix           string comment '文件后缀'
--     , file_size             bigint comment '文件大小'
--     , cdn_res_count         bigint comment 'dcdn peer资源总数'
--     , dcdn_hub_res_num      bigint comment '离线资源总数'
--     , high_res_count        bigint comment '高速资源总数'
--     , error_code            string comment '失败原因code'
--     , task_type             string comment '任务类型'
--     , hub_gcid              string comment 'hub gcid'
--     , real_gcid             string comment 'real gcid'
--     , download_time         bigint comment '下载时长'
--     , recv_bytes            bigint comment '接收字节数'
--     , vip_type              string comment '会员类型'
--     , anti_server           string comment '黄反标记'
--     , task_origin           string comment '任务来源'
--     , ref_url               string comment '访问页url'
--     , file_url              string comment '资源url原始值'
--     , global_speed          string comment '全局速度'
--     , download_strategy     bigint comment '下载策略'
--     , token                 string comment 'token'
--     , error_bytes           bigint comment '错误字节数'
--     , index_extra_data      string comment '索引风控信息'
--     , jiasu_vip_speed       bigint comment '会员加速'
--     , jiasu_super_speed     bigint comment '超级加速'
--     , jiasu_smooth          bigint comment '顺畅模式加速'
--     , jiasu_zero_speed      bigint comment '0速度补速'
--     , jiasu_group           bigint comment '抱团加速'
--     , all_bytes             bigint comment '总字节数'
--     , origin_bytes          bigint comment '原始资源字节数'
--     , server_bytes          bigint comment '镜像资源字节数'
--     , phub_bytes            bigint comment 'phub字节数'
--     , phub_peer             bigint comment 'phub资源数'
--     , tracker_bytes         bigint comment 'tracker字节数'
--     , tracker_peer          bigint comment 'tracker资源数'
--     , dcdn_bytes            bigint comment 'dcdn字节数'
--     , dcdn_peer             bigint comment 'dcdn资源数'
--     , pcdn_bytes            bigint comment 'pcdn字节数'
--     , pcdn_peer             bigint comment 'pcdn资源数'
--     , bonus_bytes           bigint comment 'bonus字节数'
--     , bonus_peer            bigint comment 'bonus资源数'
--     , phub_cdn_bytes        bigint comment 'phub cdn字节数'
--     , phub_dcdn_bytes       bigint comment 'phub dcdn字节数'
--     , xphub_bytes           bigint comment '缓存peer字节数'
--     , super_pcdn_bytes      bigint comment 'super pcdn字节数'
--     , super_pcdn_peer       bigint comment 'super pcdn资源数'
--     , phub_res_peer         bigint comment 'phub资源peer数'
--     , phub_insert_peer      bigint comment '创建channel的phub数'
--     , running_task_count_avg       bigint comment '平均并发子任务数'
--     , running_user_task_count_avg  bigint comment '平均并发主任务数'
--     , global_all_bytes      bigint comment '全局接收字节数'
--     , global_p2p_bytes      bigint comment '全局phub字节数'
--     , global_p2s_bytes      bigint comment '全局p2s字节数'
--     , global_bonus_bytes    bigint comment '全局bonus字节数'
--     , global_dcdn_bytes     bigint comment '全局dcdn字节数'
--     , global_origin_bytes   bigint comment '全局原始url字节数'
--     , query_all_hub_count   bigint comment '查种次数'
--     , query_all_hub_result  string comment '查种结果'
--     , global_speed_target_1  bigint comment '目标配速-1'
--     , global_speed_target_64 bigint comment '目标配速-64'
--     , first_insert_pcdn_peer_time bigint comment '查peer耗时，extdata[PcdnResFirstInsertTime]'
--     , global_speed_max_in_window bigint comment '边下边测最大测速，extdata[MaxGlobalDownloadSpeed]'
--     , alloc_data_buffer_fail_count bigint comment '磁盘慢限速次数'
--     , ending_span_time      bigint comment '写入磁盘耗时'
--     , player_mode           string comment '播放模式，extdata[PlayerMode]'
--     , action_type           string comment '【废弃】行为：download:下载，withdraw：取回，play：点播，other：其他'
-- )
-- comment 'dwd_迅雷云_传输库_移动端任务上报_小时增量'
-- partitioned by (
--     ds string comment '日期分区'
--     , hour string comment '小时分区'
--     , platform string comment '端：android/ios/mac/nas/harmony(含6100/6135/6136)'
-- )
-- stored as parquet;
