insert overwrite dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc
select
    download.seqid
    , download.parent_id as parentid
    , download.gcid
    , download.url as download_url
    , download.user_id
    , download.guid
    , download.peer_id as peerid
    , download.is_c_type
    , download.vip_type
    , coalesce(gcid.gcid_region, 'N/A') as server_room
    , download.carrier
    , download.province
    , download.global_speed_target
    , download.target_speed_range
    , coalesce(download.global_speed / 1024, 0) as global_speed
    , coalesce(download.global_speed_max_in_window / 1024, 0) as global_speed_max_in_window
    , coalesce(download.recv_bytes / 1024, 0) as recv_bytes
    , download.final_result
    , download.is_target_achieve
    , download.is_index
    , if(gcid.gcid is not null, '1', '0') as is_collect
    , download.is_token
    , download.is_query_hub
    , download.is_query_result
    , download.is_query_peer_slow
    , download.is_buffer_fail
    , download.is_ending_span_slow
    , download.seq_zero_speed
    , download.seq_fail
    , download.ts
    , download.download_time
    , download.event_status as eventstatus
    , download.mode
    , download.file_name
    , download.file_suffix
    , download.file_type_code
    , download.file_type_name
    , download.file_size
    , download.anti_server
    , download.is_hfk
    , download.error_code
    , download.fail_reason_code
    , download.fail_reason_name
    , download.real_gcid
    , download.ref_url as refurl
    , download.source_host
    , download.token
    , download.query_all_hub_count
    , download.query_all_hub_result
    , download.first_insert_pcdn_peer_time
    , download.alloc_data_buffer_fail_count
    , download.ending_span_time
    , download.task_type_name as task_type
    , download.download_strategy
    , coalesce(download.network_type, 'unknown') as network_type
    , case
        when download.seq_fail = '0' then '下载成功'
        when error_code in ('111151', '111152', '111153', '111154', '111155', '111156') then '资源封禁'
        when error_code in ('119238') then 'SSL证书校验失败'
        when error_code in ('111148', '111149') then '资源文件不存在'
        when error_code in ('9129', '111083', '111085', '111095', '111127', '111128') then '磁盘操作'
        when error_code in ('111179', '111180', '111181') then '纠错过多'
        when error_code in ('111136', '111176') then '长时间没收到数据0速'
        when error_code in ('114001', '114101') then 'eMule失败'
        else concat('未分类错误:', coalesce(error_code, ''))
        end as error_category
    , case
        when download.error_code in ('111151', '111152', '111153', '111154', '111155', '111156') then '封禁资源'
        when download.gcid is null or download.gcid = 'N/A' or length(download.gcid) <> 40 then '无资源无采集'
        when gcid.gcid is not null then '有采集有gcid'
        else '无采集有gcid'
        end as resource_type
    , download.service_version
    , download.product_version
    , '' as country_name
    , city_name as city
    , country_name as country
    , coalesce(download.origin_bytes, 0) as origin_bytes
    , coalesce(download.server_bytes, 0) as server_bytes
    , coalesce(download.tracker_bytes, 0) as tracker_bytes
    , coalesce(download.dcdn_bytes, 0) as dcdn_bytes
    , coalesce(download.pcdn_bytes, 0) as pcdn_bytes
    , coalesce(download.bonus_bytes, 0) as bonus_bytes
    , coalesce(download.all_bytes, 0) as all_bytes
    , download.phub_res_peer
    , download.task_origin
    , download.flag_system
    , parse_url(xl_urldecode(url),'QUERY', 'share_user_id') as share_user_id
    , coalesce(download.phub_bytes, 0) as phub_bytes
    , case
        when download.file_size >= 10485760 then 1
        else 0
        end as is_file_size_over_10mb
    , '${date}' as ds
    , download.platform
    , download.action_type
from (
    select
        seqid
        , parent_id
        , url
        , coalesce(hub_gcid, real_gcid)  as gcid
        , user_id
        , guid
        , peer_id
        , if(anti_server = '1' or cast(is_hfk as string) = '1', '1', '0') as is_c_type
        , vip_type_name as vip_type
        , carrier_name as carrier
        , prov_name    as province
        , global_speed_target
        , case
            when global_speed_target = 0 then '未上报'
            when global_speed_target > 0 and global_speed_target < 1024 * 0.5 then '(0M, 0.5M)'
            when global_speed_target >= 1024 * 0.5 and global_speed_target < 1024 then '[0.5M, 1M)'
            when global_speed_target >= 1024 and global_speed_target < 1024 * 2 then '[1M, 2M)'
            when global_speed_target >= 1024 * 2 and global_speed_target < 1024 * 3 then '[2M, 3M)'
            when global_speed_target >= 1024 * 3 and global_speed_target < 1024 * 4 then '[3M, 4M)'
            when global_speed_target >= 1024 * 4 and global_speed_target < 1024 * 5 then '[4M, 5M)'
            when global_speed_target >= 1024 * 5 and global_speed_target < 1024 * 6 then '[5M, 6M)'
            when global_speed_target >= 1024 * 6 and global_speed_target < 1024 * 7 then '[6M, 7M)'
            when global_speed_target >= 1024 * 7 and global_speed_target < 1024 * 8 then '[7M, 8M)'
            when global_speed_target >= 1024 * 8 and global_speed_target < 1024 * 9 then '[8M, 9M)'
            when global_speed_target >= 1024 * 9 and global_speed_target < 1024 * 10 then '[9M, 10M)'
            when global_speed_target >= 1024 * 10 and global_speed_target < 1024 * 20 then '[10M, 20M)'
            when global_speed_target >= 1024 * 20 and global_speed_target < 1024 * 30 then '[20M, 30M)'
            when global_speed_target >= 1024 * 30 and global_speed_target < 1024 * 40 then '[30M, 40M)'
            when global_speed_target >= 1024 * 40 and global_speed_target < 1024 * 50 then '[40M, 50M)'
            when global_speed_target >= 1024 * 50 then '50M及以上'
            else 'N/A'
        end as target_speed_range
        , global_speed
        , global_speed_max_in_window
        , recv_bytes
        , final_result
        , if(
            coalesce(global_speed_target, 0) <> 0
            and coalesce(global_speed / 1024, 0) > coalesce(global_speed_target, 0)
            , '1'
            , '0'
        ) as is_target_achieve
        , if(hub_gcid <> 'N/A', '1', '0') as is_index
        , if(token is not null, '1', '0') as is_token
        , if(cast(query_all_hub_count as bigint) > 0, '1', '0') as is_query_hub
        , if(
            (platform = 'pc' and query_all_hub_result = 'success')
            or (platform <> 'pc' and coalesce(query_all_hub_result, '0') <> '0')
            , '1'
            , '0'
        ) as is_query_result
        , if(first_insert_pcdn_peer_time > download_time * 1000 * 0.2, '1', '0') as is_query_peer_slow
        , if(alloc_data_buffer_fail_count > 0, '1', '0') as is_buffer_fail
        , if(ending_span_time > 10000 or ending_span_time > download_time * 100, '1', '0') as is_ending_span_slow
        , if(download_time > 10 and recv_bytes = 0, '1', '0') as seq_zero_speed
        , if(final_result in ('failure', 'fail'), '1', '0') as seq_fail
        , ts
        , download_time
        , event_status
        , mode
        , file_name
        , file_suffix
        , file_type_code
        , file_type_name
        , file_size
        , anti_server
        , cast(is_hfk as string) as is_hfk
        , error_code
        , fail_reason_code
        , fail_reason_name
        , real_gcid
        , ref_url
        , source_host
        , token
        , query_all_hub_count
        , query_all_hub_result
        , first_insert_pcdn_peer_time
        , alloc_data_buffer_fail_count
        , ending_span_time
        , task_type
        , task_type_name
        , download_strategy
        , network_type
        , service_version
        , product_version
        , platform
        , action_type
        , country_name
        , city_name
        , origin_bytes
        , server_bytes
        , tracker_bytes
        , dcdn_bytes
        , pcdn_bytes
        , bonus_bytes
        , all_bytes
        , phub_res_peer
        , task_origin
        , flag_system
        , phub_bytes
    from
        dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc
    where
        ds = '${date}'
        and platform in ('pc', 'android', 'ios', 'mac', 'nas', 'harmony')
        and action_type in ('download', 'withdraw')
        and task_type_name not in ('bt_main', 'magnet') -- bt主任务和子任务统计重复，磁力链即bt种子的下载任务，故过滤
) as download
left join (
    select
        gcid
        , max(section) as gcid_region
        , max(unix_timestamp(dt_committed, 'yyyy-MM-dd HH:mm:ss')) as caiji_ts
    from
        dw_xlyun.pre_xlyun_mp_gcid_info_accum
    where
        ds = '${date}'
        and action <> 'delete'
    group by
        gcid
) as gcid
on
    gcid.gcid = download.gcid
;
