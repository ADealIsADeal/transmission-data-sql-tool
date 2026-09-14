insert overwrite table dw_xlyun.dws_xlyun_transfer_download_sub_task_d_inc
select
    max_by(seqid, ts) as seqid
    , coalesce(parentid, 'N/A') as parentid
    , max(gcid) as gcid
    , coalesce(download_url, 'N/A') as download_url
    , max(user_id) as user_id
    , max(guid) as guid
    , coalesce(peerid, 'N/A') as peerid
    , max(is_c_type) as is_c_type
    , max(vip_type) as vip_type
    , max(server_room) as server_room
    , max_by(carrier, ts) as carrier
    , max_by(province, ts) as province
    , max_by(global_speed_target, ts) as global_speed_target
    , cast(null as string) as target_speed_range
    , avg(if(global_speed is not null and global_speed <> 0, global_speed, null)) as global_speed
    , max(global_speed_max_in_window) as global_speed_max_in_window
    , sum(recv_bytes) as recv_bytes
    , max_by(final_result, ts) as final_result
    , max_by(is_target_achieve, ts) as is_target_achieve
    , max_by(is_index, ts) as is_index
    , max_by(is_collect, ts) as is_collect
    , max_by(is_token, ts) as is_token
    , max_by(is_query_hub, ts) as is_query_hub
    , max_by(is_query_result, ts) as is_query_result
    , max_by(is_query_peer_slow, ts) as is_query_peer_slow
    , max_by(is_buffer_fail, ts) as is_buffer_fail
    , max_by(is_ending_span_slow, ts) as is_ending_span_slow
    , if(sum(if(seq_zero_speed = '1', 1, 0)) = count(1), '1', '0') as seq_zero_speed
    , max_by(seq_fail, ts) as seq_fail
    , max(ts) as ts
    , sum(download_time) as download_time
    , max_by(eventstatus, ts) as eventstatus
    , min_by(mode, ts) as mode
    , max(file_name) as file_name
    , max_by(file_suffix, ts) as file_suffix
    , max_by(file_type_code, ts) as file_type_code
    , max_by(file_type_name, ts) as file_type_name
    , max(file_size) as file_size
    , max_by(anti_server, ts) as anti_server
    , max_by(is_hfk, ts) as is_hfk
    , max_by(error_code, ts) as error_code
    , max_by(fail_reason_code, ts) as fail_reason_code
    , max_by(fail_reason_name, ts) as fail_reason_name
    , max_by(real_gcid, ts) as real_gcid
    , max_by(refurl, ts) as refurl
    , max_by(source_host, ts) as source_host
    , max_by(token, ts) as token
    , max_by(query_all_hub_count, ts) as query_all_hub_count
    , max_by(query_all_hub_result, ts) as query_all_hub_result
    , max_by(first_insert_pcdn_peer_time, ts) as first_insert_pcdn_peer_time
    , sum(alloc_data_buffer_fail_count) as alloc_data_buffer_fail_count
    , sum(ending_span_time) as ending_span_time
    , max_by(task_type, ts) as task_type
    , max_by(download_strategy, ts) as download_strategy
    , max(network_type) as network_type
    , max_by(error_category, ts) as error_category
    , max_by(resource_type, ts) as resource_type
    , max_by(service_version, ts) as service_version
    , max_by(product_version, ts) as product_version
    , max_by(country, ts) as country
    , max_by(city, ts) as city
    , sum(origin_bytes) as origin_bytes
    , sum(server_bytes) as server_bytes
    , sum(tracker_bytes) as tracker_bytes
    , sum(dcdn_bytes) as dcdn_bytes
    , sum(pcdn_bytes) as pcdn_bytes
    , sum(bonus_bytes) as bonus_bytes
    , sum(all_bytes) as all_bytes
    , max(phub_res_peer) as phub_res_peer
    , max(task_origin) as task_origin
    , max(flag_system) as flag_system
    , max(share_user_id) as share_user_id
    , sum(phub_bytes) as phub_bytes
    , max(is_file_size_over_10mb) as is_file_size_over_10mb
    , '${date}' as ds
    , platform
    , action_type
from
    dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc
where
    ds = '${date}'
group by
    coalesce(peerid, 'N/A')
    , coalesce(parentid, 'N/A')
    , coalesce(download_url, 'N/A')
    , platform
    , action_type
;
