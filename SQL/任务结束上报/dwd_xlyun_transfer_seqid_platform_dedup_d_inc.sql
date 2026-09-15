------------------------------------------------------------
--  FILE:    dwd_xlyun_transfer_seqid_platform_dedup_d_inc.sql
--  DESC:    传输库分片去重中间表（日增量；读小时 DWD 当日全量；按 ts 取最新）
--  CHANGE:  20260703 从宽表脚本抽出去重逻辑，独立落表
--  PARAM:   ds='${date}'
--  UPSTREAM: dwd_xlyun_transfer_pc_log_h_inc, dwd_xlyun_transfer_log_h_inc（当日全部 hour）
--  DEP:     日调度需在当日 24 个小时 DWD 分区就绪后执行
------------------------------------------------------------

with base_union as (
    select
        peer_id
        , user_id
        , guid
        , parent_id
        , seqid
        , event_id
        , cast(server_info as string) as server_info
        , cmdid
        , appid
        , service_version
        , product_version
        , service_name
        , extdata_head
        , process_id
        , ip
        , attribute1
        , attribute2
        , cost1
        , cost2
        , cost3
        , cost4
        , final_result
        , '' as event_status
        , mode
        , file_name
        , file_suffix
        , file_size
        , extdata
        , cdn_res_count
        , dcdn_hub_res_num
        , high_res_count
        , error_code
        , task_type
        , hub_gcid
        , real_gcid
        , download_time
        , recv_bytes
        , vip_type
        , anti_server
        , task_origin
        , ref_url
        , file_url
        , cast(global_speed as bigint) as global_speed
        , download_strategy
        , token
        , error_bytes
        , index_extra_data
        , ts
        , jiasu_vip_speed
        , jiasu_super_speed
        , jiasu_smooth
        , jiasu_zero_speed
        , jiasu_group
        , all_bytes
        , origin_bytes
        , server_bytes
        , phub_bytes
        , phub_peer
        , tracker_bytes
        , tracker_peer
        , dcdn_bytes
        , dcdn_peer
        , pcdn_bytes
        , pcdn_peer
        , bonus_bytes
        , bonus_peer
        , phub_cdn_bytes
        , phub_dcdn_bytes
        , xphub_bytes
        , super_pcdn_bytes
        , super_pcdn_peer
        , phub_res_peer
        , phub_insert_peer
        , running_task_count_avg
        , running_user_task_count_avg
        , global_all_bytes
        , global_p2p_bytes
        , global_p2s_bytes
        , global_bonus_bytes
        , global_dcdn_bytes
        , global_origin_bytes
        , etag
        , query_all_hub_count
        , query_all_hub_result
        , global_speed_target_1
        , global_speed_target_64
        , first_insert_pcdn_peer_time
        , alloc_data_buffer_fail_count
        , global_speed_max_in_window
        , ending_span_time
        , is_netdisk_fetch_task
        , first_video_mode
        , cast(null as string) as player_mode
        , platform
        , case
            when coalesce(is_netdisk_fetch_task, '0') = '1' then 'withdraw'
            when first_video_mode = '2' then 'play'
            else 'download'
            end action_type
        , row_number() over(partition by platform, seqid, parent_id, file_url, peer_id order by ts desc) as rn
    from
        dw_xlyun.dwd_xlyun_transfer_pc_log_h_inc
    where
        ds = '${date}'

    union all

    select
        peer_id
        , coalesce(user_id_parsed, user_id) as user_id
        , guid
        , parent_id
        , cast(seqid as string) as seqid
        , event_id
        , cast(server_info as string) server_info
        , cmdid
        , appid
        , service_version
        , product_version
        , service_name
        , extdata_head
        , process_id
        , ip
        , '' as attribute1
        , '' as attribute2
        , 0 as cost1
        , 0 as cost2
        , 0 as cost3
        , 0 as cost4
        , final_result
        , cast(event_status as string) as event_status
        , mode
        , file_name
        , file_suffix
        , file_size
        , extdata
        , cdn_res_count
        , dcdn_hub_res_num
        , high_res_count
        , error_code
        , task_type
        , hub_gcid
        , real_gcid
        , download_time
        , recv_bytes
        , vip_type
        , anti_server
        , task_origin
        , ref_url
        , file_url
        , cast(global_speed as bigint) as global_speed
        , download_strategy
        , token
        , error_bytes
        , index_extra_data
        , ts
        , jiasu_vip_speed
        , jiasu_super_speed
        , jiasu_smooth
        , jiasu_zero_speed
        , jiasu_group
        , all_bytes
        , origin_bytes
        , server_bytes
        , phub_bytes
        , phub_peer
        , tracker_bytes
        , tracker_peer
        , dcdn_bytes
        , dcdn_peer
        , pcdn_bytes
        , pcdn_peer
        , bonus_bytes
        , bonus_peer
        , phub_cdn_bytes
        , phub_dcdn_bytes
        , xphub_bytes
        , super_pcdn_bytes
        , super_pcdn_peer
        , phub_res_peer
        , phub_insert_peer
        , running_task_count_avg
        , running_user_task_count_avg
        , global_all_bytes
        , global_p2p_bytes
        , global_p2s_bytes
        , global_bonus_bytes
        , global_dcdn_bytes
        , global_origin_bytes
        , '' as etag
        , query_all_hub_count
        , query_all_hub_result
        , cast(split(str_to_map(xl_urldecode(extdata['LevelStrategy']), ';', '\\|')['1'], '-')[0] as bigint) as global_speed_target_1
        , cast(split(str_to_map(xl_urldecode(extdata['LevelStrategy']), ';', '\\|')['64'], '-')[0] as bigint) as global_speed_target_64
        , first_insert_pcdn_peer_time
        , alloc_data_buffer_fail_count
        , global_speed_max_in_window
        , ending_span_time
        , cast(null as string) as is_netdisk_fetch_task
        , cast(null as string) as first_video_mode
        , player_mode
        , platform
        , case
            when task_type in ('1', '3', '4', '16') or (task_type = '12' and player_mode = '-1' ) then 'download'
            when task_type in ('12','14') and player_mode = '2' then 'withdraw'
            when task_type in ('12','14') and player_mode in('0', '1') then 'play'
            else 'other'
            end as action_type
        , row_number() over(partition by platform, seqid, parent_id, file_url, peer_id order by ts desc) as rn
    from
        dw_xlyun.dwd_xlyun_transfer_log_h_inc
    where
        ds = '${date}'
)

insert overwrite table dw_xlyun.dwd_xlyun_transfer_seqid_platform_dedup_d_inc partition (ds = '${date}', platform, action_type)
select
    ranked.peer_id
    , ranked.user_id
    , ranked.guid
    , ranked.parent_id
    , ranked.seqid
    , ranked.event_id
    , ranked.server_info
    , ranked.cmdid
    , ranked.appid
    , ranked.service_version
    , ranked.product_version
    , ranked.service_name
    , ranked.extdata_head
    , ranked.process_id
    , ranked.ip
    , ranked.attribute1
    , ranked.attribute2
    , ranked.cost1
    , ranked.cost2
    , ranked.cost3
    , ranked.cost4
    , ranked.final_result
    , ranked.event_status
    , ranked.mode
    , ranked.file_name
    , ranked.file_suffix
    , ranked.file_size
    , ranked.extdata
    , ranked.cdn_res_count
    , ranked.dcdn_hub_res_num
    , ranked.high_res_count
    , ranked.error_code
    , ranked.task_type
    , ranked.hub_gcid
    , ranked.real_gcid
    , ranked.download_time
    , ranked.recv_bytes
    , ranked.vip_type
    , ranked.anti_server
    , ranked.task_origin
    , ranked.ref_url
    , ranked.file_url
    , ranked.global_speed
    , ranked.download_strategy
    , ranked.token
    , ranked.error_bytes
    , ranked.index_extra_data
    , ranked.ts
    , ranked.jiasu_vip_speed
    , ranked.jiasu_super_speed
    , ranked.jiasu_smooth
    , ranked.jiasu_zero_speed
    , ranked.jiasu_group
    , ranked.all_bytes
    , ranked.origin_bytes
    , ranked.server_bytes
    , ranked.phub_bytes
    , ranked.phub_peer
    , ranked.tracker_bytes
    , ranked.tracker_peer
    , ranked.dcdn_bytes
    , ranked.dcdn_peer
    , ranked.pcdn_bytes
    , ranked.pcdn_peer
    , ranked.bonus_bytes
    , ranked.bonus_peer
    , ranked.phub_cdn_bytes
    , ranked.phub_dcdn_bytes
    , ranked.xphub_bytes
    , ranked.super_pcdn_bytes
    , ranked.super_pcdn_peer
    , ranked.phub_res_peer
    , ranked.phub_insert_peer
    , ranked.running_task_count_avg
    , ranked.running_user_task_count_avg
    , ranked.global_all_bytes
    , ranked.global_p2p_bytes
    , ranked.global_p2s_bytes
    , ranked.global_bonus_bytes
    , ranked.global_dcdn_bytes
    , ranked.global_origin_bytes
    , ranked.etag
    , ranked.query_all_hub_count
    , ranked.query_all_hub_result
    , ranked.global_speed_target_1
    , ranked.global_speed_target_64
    , ranked.first_insert_pcdn_peer_time
    , ranked.alloc_data_buffer_fail_count
    , ranked.global_speed_max_in_window
    , ranked.ending_span_time
    , ranked.is_netdisk_fetch_task
    , ranked.first_video_mode
    , ranked.player_mode
    , ranked.platform
    , ranked.action_type
from
    base_union as ranked
where
    ranked.rn = 1
;

-- create table dw_xlyun.dwd_xlyun_transfer_seqid_platform_dedup_d_inc (
--     peer_id                          string comment '传输库id'
--     , user_id                        string comment '用户id'
--     , guid                           string comment '设备id'
--     , parent_id                      string comment '主任务id'
--     , seqid                          string comment '下载分片id'
--     , event_id                       string comment '事件id'
--     , server_info                    string comment 'server_info'
--     , cmdid                          bigint comment '命令id'
--     , appid                          string comment '产品id'
--     , service_version                string comment '客户端版本'
--     , product_version                string comment '下载库版本号'
--     , service_name                   string comment '产品id'
--     , extdata_head                   string comment ''
--     , process_id                     string comment '进程识别号'
--     , ip                             string comment '客户端ip'
--     , attribute1                     string comment ''
--     , attribute2                     string comment ''
--     , cost1                          bigint comment ''
--     , cost2                          bigint comment ''
--     , cost3                          bigint comment ''
--     , cost4                          bigint comment ''
--     , final_result                   string comment '下载结果'
--     , event_status                   string comment '任务状态'
--     , mode                           string comment '续传类型'
--     , file_name                      string comment '文件名'
--     , file_suffix                    string comment '文件后缀'
--     , file_size                      bigint comment '文件大小'
--     , extdata                        map<string, string> comment '拓展字段'
--     , cdn_res_count                  bigint comment 'dcdn peer资源总数'
--     , dcdn_hub_res_num               bigint comment '离线资源总数'
--     , high_res_count                 bigint comment '高速资源总数'
--     , error_code                     string comment '失败原因原始code'
--     , task_type                      string comment '任务类型'
--     , hub_gcid                       string comment 'hub gcid'
--     , real_gcid                      string comment 'real gcid'
--     , download_time                  bigint comment '分片下载时长'
--     , recv_bytes                     bigint comment '接收字节数'
--     , vip_type                       string comment '会员类型'
--     , anti_server                    string comment '黄反标记'
--     , task_origin                    string comment '任务来源'
--     , ref_url                        string comment '访问页url'
--     , file_url                       string comment '资源url（未decode）'
--     , global_speed                   bigint comment '全局速度'
--     , download_strategy              bigint comment '下载策略'
--     , token                          string comment 'token'
--     , error_bytes                    bigint comment '错误字节数'
--     , index_extra_data               string comment '索引风控信息'
--     , ts                             string comment '上报时间'
--     , jiasu_vip_speed                bigint comment '会员加速'
--     , jiasu_super_speed              bigint comment '超级加速'
--     , jiasu_smooth                   bigint comment '顺畅模式加速'
--     , jiasu_zero_speed               bigint comment '0速度补速'
--     , jiasu_group                    bigint comment '抱团加速'
--     , all_bytes                      bigint comment '总字节数'
--     , origin_bytes                   bigint comment '原始资源字节数'
--     , server_bytes                   bigint comment '镜像资源字节数'
--     , phub_bytes                     bigint comment 'phub字节数'
--     , phub_peer                      bigint comment 'phub资源数'
--     , tracker_bytes                  bigint comment 'tracker字节数'
--     , tracker_peer                   bigint comment 'tracker资源数'
--     , dcdn_bytes                     bigint comment 'dcdn字节数'
--     , dcdn_peer                      bigint comment 'dcdn资源数'
--     , pcdn_bytes                     bigint comment 'pcdn字节数'
--     , pcdn_peer                      bigint comment 'pcdn资源数'
--     , bonus_bytes                    bigint comment 'bonus字节数'
--     , bonus_peer                     bigint comment 'bonus资源数'
--     , phub_cdn_bytes                 bigint comment 'phub cdn字节数'
--     , phub_dcdn_bytes                bigint comment 'phub dcdn字节数'
--     , xphub_bytes                    bigint comment '缓存peer字节数'
--     , super_pcdn_bytes               bigint comment 'super pcdn字节数'
--     , super_pcdn_peer                bigint comment 'super pcdn资源数'
--     , phub_res_peer                  bigint comment 'phub资源peer数'
--     , phub_insert_peer               bigint comment '创建channel的phub数'
--     , running_task_count_avg         bigint comment '平均并发子任务数'
--     , running_user_task_count_avg    bigint comment '平均并发主任务数'
--     , global_all_bytes               bigint comment '全局接收字节数'
--     , global_p2p_bytes               bigint comment '全局phub字节数'
--     , global_p2s_bytes               bigint comment '全局p2s字节数'
--     , global_bonus_bytes             bigint comment '全局bonus字节数'
--     , global_dcdn_bytes              bigint comment '全局dcdn字节数'
--     , global_origin_bytes            bigint comment '全局原始url字节数'
--     , etag                           string comment 'etag'
--     , query_all_hub_count            string comment '查种次数'
--     , query_all_hub_result           string comment '查种结果'
--     , global_speed_target_1          bigint comment '目标配速1'
--     , global_speed_target_64         bigint comment '目标配速64'
--     , first_insert_pcdn_peer_time    bigint comment '查peer耗时'
--     , alloc_data_buffer_fail_count   bigint comment '磁盘慢限速次数'
--     , global_speed_max_in_window     bigint comment '边下边测最大测速'
--     , ending_span_time               bigint comment '写入磁盘耗时'
--     , is_netdisk_fetch_task          string comment '是否网盘取回任务'
--     , first_video_mode               string comment '点播模式'
--     , player_mode                    string comment '播放模式'
-- )
-- comment 'dwd_迅雷云_传输库_分片去重中间表'
-- partitioned by (
--     ds string comment '日期分区'
--     , platform string comment '端'
--     , action_type string comment '行为：download:下载，withdraw：取回，play：点播，other：其他'
-- )
-- stored as parquet;
