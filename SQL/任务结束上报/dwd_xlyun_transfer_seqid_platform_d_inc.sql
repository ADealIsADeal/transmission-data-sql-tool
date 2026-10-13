------------------------------------------------------------
--  FILE:    dwd_xlyun_transfer_seqid_platform_d_inc.sql
--  DESC:    传输库分片宽表 DWD 替换验证表（日增量；小时 DWD 日去重后字段加工）
--  CHANGE:  20260911 鸿蒙拆分 harmony_mobile/harmony_pc/harmony_pad；
--           PC 新增 6061 HLS；移动端 action_type 按 TaskScene/PlayScene/DataFileMode 调整；
--           新增 play_scene/task_scene/data_file_mode 下沉到日 DWD
--           20260916 HFK join 前拆出 hub_gcid 为 null/空串/'null' 的行，避免 SMJ 按脏 key 倾斜
--  PARAM:   ds='${date}'
--  UPSTREAM: dwd_xlyun_transfer_pc_log_h_inc, dwd_xlyun_transfer_log_h_inc
--            dim_xlyun_transfer_gcid_forbidden_hfk_d_inc, dim_pub_sundry_manual_full
--  DEP:     日调度需在当日 24 个小时 DWD 分区就绪后执行
--  NOTE:    只写入 _swap，不改现网 dwd_xlyun_transfer_seqid_platform_d_inc / 小时表 / 现网 dedup
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
        , cast(null as string) as play_scene
        , cast(null as string) as task_scene
        , cast(null as string) as data_file_mode
        , platform
        , case
            when coalesce(is_netdisk_fetch_task, '0') = '1' then 'withdraw'
            when first_video_mode = '2' then 'play'
            else 'download'
        end as action_type
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
        , cast(server_info as string) as server_info
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
        , extdata['PlayScene'] as play_scene
        , extdata['TaskScene'] as task_scene
        , extdata['DataFileMode'] as data_file_mode
        -- 6061 并入 pc；6100/6135/6136 拆分鸿蒙三端；其余保持小时表 platform
        , case
            when service_name = '6061' then 'pc'
            when service_name = '6100' then 'harmony_mobile'
            when service_name = '6135' then 'harmony_pc'
            when service_name = '6136' then 'harmony_pad'
            else platform
        end as platform
        , case
            -- 下载：TaskScene=1；或 TaskScene 为空时的普通下载（16暂定）
            when extdata['TaskScene'] = '1'
                or (
                    coalesce(extdata['TaskScene'],'0') = '0'
                    and (
                        (task_type in ('1', '3', '4', '16') and nvl(extdata['DataFileMode'], 0) = 0)
                        or (task_type = '12' and player_mode = '-1')
                    )
                )
                then 'download'
            -- 取回：TaskScene=2；或 TaskScene 为空时的云盘取回
            when extdata['TaskScene'] = '2'
                or (
                    coalesce(extdata['TaskScene'],'0') = '0'
                    and task_type in ('12', '14')
                    and player_mode = '2'
                )
                then 'withdraw'
            -- 播放：点播 SDK / TaskScene=3 / 传统云盘播放 / 非0 DataFileMode
            when nvl(cast(extdata['PlayScene'] as bigint), -1) >= 0
                or extdata['TaskScene'] = '3'
                or (task_type in ('12', '14') and player_mode in ('0', '1'))
                or (task_type in ('1', '3', '4') and nvl(extdata['DataFileMode'], 0) <> 0)
                then 'play'
            else 'other'
        end as action_type
    from
        dw_xlyun.dwd_xlyun_transfer_log_h_inc
    where
        ds = '${date}'
)

, ranked as (
    select
        peer_id
        , user_id
        , guid
        , parent_id
        , seqid
        , event_id
        , server_info
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
        , event_status
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
        , global_speed
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
        , player_mode
        , play_scene
        , task_scene
        , data_file_mode
        , platform
        , action_type
        , row_number() over(partition by platform, seqid, parent_id, file_url, peer_id order by ts desc) as rn
    from
        base_union
)

-- 去重后再拆 HFK join：null/空串/字面量 'null' 约占 28%，SMJ 会打成超热分区
, dedup as (
    select
        peer_id
        , user_id
        , guid
        , parent_id
        , seqid
        , event_id
        , server_info
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
        , event_status
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
        , xl_urldecode(xl_urldecode(file_url)) as url
        , global_speed
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
        , player_mode
        , play_scene
        , task_scene
        , data_file_mode
        , platform
        , action_type
    from
        ranked
    where
        rn = 1
)

, joined as (
    select
        d.*
        , if(hfk.hubgcid is not null, 1, 0) as is_hfk
    from (
        select
            *
        from
            dedup
        where
            hub_gcid is not null
            and hub_gcid not in ('', 'null')
    ) as d
    left join (
        select
            hubgcid
        from
            dw_xlyun.dim_xlyun_transfer_gcid_forbidden_hfk_d_inc
        where
            ds = '${date}'
            and coalesce(hubgcid, '') <> ''
            and hubgcid <> 'null'
        group by
            hubgcid
    ) as hfk
    on
        d.hub_gcid = hfk.hubgcid

    union all

    select
        d.*
        , 0 as is_hfk
    from
        dedup as d
    where
        d.hub_gcid is null
        or d.hub_gcid in ('', 'null')
)

insert overwrite table dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc partition (ds = '${date}', platform, action_type)
select /*+ MAPJOIN(dim_pub1, dim_pub2) */
    joined.peer_id
    , joined.user_id
    , joined.guid
    , joined.parent_id
    , joined.seqid
    , joined.event_id
    , cast(joined.server_info as string) as server_info
    , joined.cmdid
    , joined.appid
    , joined.service_version
    , joined.product_version
    , joined.service_name
    , joined.extdata_head
    , joined.process_id
    , joined.ip
    , joined.attribute1
    , joined.attribute2
    , joined.cost1
    , joined.cost2
    , joined.cost3
    , joined.cost4
    , coalesce(joined.final_result, 'N/A') as final_result
    , joined.event_status
    , case
        when joined.mode = '0' then 'new'
        when joined.mode = '1' then 'continue'
        when joined.mode is null then 'N/A'
        else joined.mode
    end as mode
    , joined.file_name
    , joined.file_suffix
    , coalesce(dim_pub1.dim_value, 'N/A') as file_type_code
    , coalesce(dim_pub1.dim_value_desc, 'N/A') as file_type_name
    , joined.file_size
    , joined.extdata
    , joined.cdn_res_count
    , joined.dcdn_hub_res_num
    , joined.high_res_count
    , joined.error_code
    , coalesce(dim_pub2.dim_key, 'N/A') as fail_reason_code
    , coalesce(dim_pub2.dim_value, 'N/A') as fail_reason_name
    , joined.task_type
    , if(length(joined.hub_gcid) = 40, joined.hub_gcid, 'N/A') as hub_gcid
    , if(length(joined.real_gcid) = 40, joined.real_gcid, 'N/A') as real_gcid
    , joined.download_time
    , joined.recv_bytes
    , joined.vip_type
    , '' as is_vip
    , joined.anti_server
    , joined.is_hfk
    , joined.task_origin
    , '' as prov_id
    , '' as city_id
    , '' as sp_id
    , joined.ref_url
    , if(length(parse_url(joined.ref_url, 'HOST')) >= 1, parse_url(joined.ref_url, 'HOST'), 'unknown') as source_host
    , joined.url
    , cast(joined.global_speed as bigint) as global_speed
    , joined.download_strategy
    , joined.token
    , cast(joined.error_bytes as bigint) as error_bytes
    , joined.index_extra_data
    , joined.ts
    , joined.jiasu_vip_speed
    , joined.jiasu_super_speed
    , joined.jiasu_smooth
    , joined.jiasu_zero_speed
    , joined.jiasu_group
    , joined.all_bytes
    , joined.origin_bytes
    , joined.server_bytes
    , joined.phub_bytes
    , joined.phub_peer
    , joined.tracker_bytes
    , joined.tracker_peer
    , joined.dcdn_bytes
    , joined.dcdn_peer
    , joined.pcdn_bytes
    , joined.pcdn_peer
    , joined.bonus_bytes
    , joined.bonus_peer
    , joined.phub_cdn_bytes
    , joined.phub_dcdn_bytes
    , joined.xphub_bytes
    , joined.super_pcdn_bytes
    , joined.super_pcdn_peer
    , joined.phub_res_peer
    , joined.phub_insert_peer
    , joined.running_task_count_avg
    , joined.running_user_task_count_avg
    , joined.global_all_bytes
    , joined.global_p2p_bytes
    , joined.global_p2s_bytes
    , joined.global_bonus_bytes
    , joined.global_dcdn_bytes
    , joined.global_origin_bytes
    , joined.etag
    , joined.query_all_hub_count
    , nvl(joined.query_all_hub_result, 'N/A') as query_all_hub_result
    , coalesce(joined.global_speed_target_64, joined.global_speed_target_1, 0) as global_speed_target
    , joined.first_insert_pcdn_peer_time
    , joined.alloc_data_buffer_fail_count
    , joined.global_speed_max_in_window
    , joined.ending_span_time
    , joined.is_netdisk_fetch_task
    , joined.first_video_mode
    , joined.player_mode
    , split(ip_parser(joined.ip), ',')[0] as country_name
    , split(ip_parser(joined.ip), ',')[1] as prov_name
    , split(ip_parser(joined.ip), ',')[2] as city_name
    , split(ip_parser(joined.ip), ',')[3] as carrier_name
    , if(joined.service_name = '6061', joined.extdata['NetworkType'], if(joined.platform = 'pc', joined.extdata['NetWorkType'], joined.extdata['NetworkType'])) as network_type
    , case
        when joined.action_type = 'withdraw' then 0
        when joined.action_type = 'download'
            and (
                joined.url like '%sandai%'
                or joined.url like '%backstage-file-ssl.a.88cdn.com/pc/upgrade/%'
                or joined.url like '%static-xl9-ssl.xunlei.com%'
                or joined.url like '%xlgameupdate%'
                or joined.url like '%admin.xl9.xunlei.com%'
                or joined.url like '%static-pc.xunlei.com%'
                or joined.url like '%xunleisetup%'
                or joined.url like '%xunlei.com%'
            )
        then 1
        else 0
    end as flag_system
    , case
        when joined.service_name = '6061' then 'hls'
        when joined.task_type in ('1', '14', '4635') then 'p2sp'
        when joined.task_type in ('4636') then 'bt_main'
        when joined.task_type in ('3', '4637') then 'bt'
        when joined.task_type in ('4', '4638') then 'emule'
        when joined.task_type in ('4639') then 'magnet'
        when joined.task_type in ('12', '16') then 'hls'
        else 'other'
    end as task_type_name
    , case
        when joined.vip_type in ('2', 'normal') then '1'
        when joined.vip_type in ('3', 'platinum') then '3'
        when joined.vip_type in ('super', '5') then '5'
        else '0'
    end as vip_type_name
    , joined.play_scene
    , joined.task_scene
    , joined.data_file_mode
    , joined.platform
    , joined.action_type
from
    joined
left join (
    select
        dim_key
        , dim_value
        , dim_value_desc
    from
        dw_xlyun.dim_pub_sundry_manual_full
    where
        dim_type = 'file_type'
) as dim_pub1
on
    dim_pub1.dim_key = joined.file_suffix
left join (
    select
        dim_key
        , dim_value
        , dim_value_desc
    from
        dw_xlyun.dim_pub_sundry_manual_full
    where
        dim_type = 'download_error_type'
) as dim_pub2
on
    dim_pub2.dim_key = joined.error_code
;


-- create table dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc (
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
--     , extdata_head                   string comment '扩展头'
--     , process_id                     string comment '进程识别号'
--     , ip                             string comment '客户端ip'
--     , attribute1                     string comment '预留属性1'
--     , attribute2                     string comment '预留属性2'
--     , cost1                          bigint comment '预留耗时1'
--     , cost2                          bigint comment '预留耗时2'
--     , cost3                          bigint comment '预留耗时3'
--     , cost4                          bigint comment '预留耗时4'
--     , final_result                   string comment '下载结果'
--     , event_status                   string comment '任务状态'
--     , mode                           string comment '续传类型；new/continue/N/A'
--     , file_name                      string comment '文件名'
--     , file_suffix                    string comment '文件后缀'
--     , file_type_code                 string comment '文件类型'
--     , file_type_name                 string comment '文件类型中文名'
--     , file_size                      bigint comment '文件大小，单位字节'
--     , extdata                        map<string, string> comment '拓展字段'
--     , cdn_res_count                  bigint comment 'dcdn peer资源总数'
--     , dcdn_hub_res_num               bigint comment '离线资源总数'
--     , high_res_count                 bigint comment '高速资源总数'
--     , error_code                     string comment '失败原因原始code'
--     , fail_reason_code               string comment '失败原因code'
--     , fail_reason_name               string comment '失败原因中文名'
--     , task_type                      string comment '任务类型原始码'
--     , hub_gcid                       string comment 'hub gcid'
--     , real_gcid                      string comment 'real gcid'
--     , download_time                  bigint comment '分片下载时长'
--     , recv_bytes                     bigint comment '接收字节数，单位字节'
--     , vip_type                       string comment '会员类型原始值'
--     , is_vip                         string comment '会员类型，现网固定空串'
--     , anti_server                    string comment '黄反标记'
--     , is_hfk                         bigint comment '是否命中黄反库；1是，0否'
--     , task_origin                    string comment '任务来源'
--     , prov_id                        string comment '省份，现网占位空串'
--     , city_id                        string comment '城市，现网占位空串'
--     , sp_id                          string comment '运营商，现网占位空串'
--     , ref_url                        string comment '访问页url'
--     , source_host                    string comment '来源网站'
--     , url                            string comment '资源url'
--     , global_speed                   bigint comment '全局速度'
--     , download_strategy              bigint comment '下载策略'
--     , token                          string comment 'token'
--     , error_bytes                    bigint comment '错误字节数，单位字节'
--     , index_extra_data               string comment '索引风控信息'
--     , ts                             string comment '上报时间'
--     , jiasu_vip_speed                bigint comment '会员加速'
--     , jiasu_super_speed              bigint comment '超级加速'
--     , jiasu_smooth                   bigint comment '顺畅模式加速'
--     , jiasu_zero_speed               bigint comment '0速度补速'
--     , jiasu_group                    bigint comment '抱团加速'
--     , all_bytes                      bigint comment '总字节数，单位字节'
--     , origin_bytes                   bigint comment '原始资源字节数，单位字节'
--     , server_bytes                   bigint comment '镜像资源字节数，单位字节'
--     , phub_bytes                     bigint comment 'phub字节数，单位字节'
--     , phub_peer                      bigint comment 'phub资源数'
--     , tracker_bytes                  bigint comment 'tracker字节数，单位字节'
--     , tracker_peer                   bigint comment 'tracker资源数'
--     , dcdn_bytes                     bigint comment 'dcdn字节数，单位字节'
--     , dcdn_peer                      bigint comment 'dcdn资源数'
--     , pcdn_bytes                     bigint comment 'pcdn字节数，单位字节'
--     , pcdn_peer                      bigint comment 'pcdn资源数'
--     , bonus_bytes                    bigint comment 'bonus字节数，单位字节'
--     , bonus_peer                     bigint comment 'bonus资源数'
--     , phub_cdn_bytes                 bigint comment 'phub cdn字节数，单位字节'
--     , phub_dcdn_bytes                bigint comment 'phub dcdn字节数，单位字节'
--     , xphub_bytes                    bigint comment '缓存peer字节数，单位字节'
--     , super_pcdn_bytes               bigint comment 'super pcdn字节数，单位字节'
--     , super_pcdn_peer                bigint comment 'super pcdn资源数'
--     , phub_res_peer                  bigint comment 'phub资源peer数'
--     , phub_insert_peer               bigint comment '创建channel的phub数'
--     , running_task_count_avg         bigint comment '平均并发子任务数'
--     , running_user_task_count_avg    bigint comment '平均并发主任务数'
--     , global_all_bytes               bigint comment '全局接收字节数，单位字节'
--     , global_p2p_bytes               bigint comment '全局phub字节数，单位字节'
--     , global_p2s_bytes               bigint comment '全局p2s字节数，单位字节'
--     , global_bonus_bytes             bigint comment '全局bonus字节数，单位字节'
--     , global_dcdn_bytes              bigint comment '全局dcdn字节数，单位字节'
--     , global_origin_bytes            bigint comment '全局原始url字节数，单位字节'
--     , etag                           string comment 'etag'
--     , query_all_hub_count            string comment '查种次数'
--     , query_all_hub_result           string comment '查种结果'
--     , global_speed_target            bigint comment '目标配速'
--     , first_insert_pcdn_peer_time    bigint comment '查peer耗时'
--     , alloc_data_buffer_fail_count   bigint comment '磁盘慢限速次数'
--     , global_speed_max_in_window     bigint comment '边下边测最大测速'
--     , ending_span_time               bigint comment '写入磁盘耗时'
--     , is_netdisk_fetch_task          string comment '是否网盘取回任务，PC extdata[isnetdiskfetchtask]'
--     , first_video_mode               string comment '点播模式，PC extdata[firstvideomode]'
--     , player_mode                    string comment '播放模式，移动端 extdata[PlayerMode]'
--     , country_name                   string comment '国家；客户端ip解析'
--     , prov_name                      string comment '省份'
--     , city_name                      string comment '城市'
--     , carrier_name                   string comment '运营商'
--     , network_type                   string comment '网络类型'
--     , flag_system                    bigint comment '是否迅雷自有插件类任务，1：是，0：否'
--     , task_type_name                 string comment '任务类型，p2sp/bt_main/bt/emule/magnet/hls/other；6061强制hls'
--     , vip_type_name                  string comment '会员类型，1：普通，3：白金，5：超会，0：非会员'
--     , play_scene                     string comment '播放场景，移动端 extdata[PlayScene]；PC为空；20260911新增'
--     , task_scene                     string comment '任务场景，移动端 extdata[TaskScene]；PC为空；20260911新增'
--     , data_file_mode                 string comment '数据文件模式，移动端 extdata[DataFileMode]；PC为空；20260914新增'
--     , play_scene                     string comment '播放场景，移动端 extdata[PlayScene]；PC为空；20260911新增'
--     , task_scene                     string comment '任务场景，移动端 extdata[TaskScene]；PC为空；20260911新增'
--     , data_file_mode                 string comment '数据文件模式，移动端 extdata[DataFileMode]；PC为空；20260914新增'
-- )
-- comment 'dwd_迅雷云_传输库_任务退出上报_宽表_口径调整替换验证'
-- partitioned by (
--     ds string comment '日期分区，yyyyMMdd'
--     , platform string comment '端；pc/android/ios/mac/nas/harmony_mobile/harmony_pc/harmony_pad/other'
--     , action_type string comment '行为：download:下载，withdraw：取回，play：点播，other：其他'
-- )
-- stored as parquet;