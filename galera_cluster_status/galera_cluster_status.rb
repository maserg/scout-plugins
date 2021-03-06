class GaleraClusterStatus < Scout::Plugin
  OPTIONS=<<-EOS
    mysql_command:
      default: sudo mysql
      name: Command to run the mysql client 
  EOS

  def build_report
    @mysql_command = option(:mysql_command) || "sudo mysql"
    status = mysql_query("show status like 'wsrep%'")
    report(
      :local_state => status[:wsrep_local_state].to_i,
      :local_state_comment => status[:wsrep_local_state_comment],
      :flow_control_paused => status[:wsrep_flow_control_paused].to_i,
      :local_recv_queue_avg => status[:wsrep_local_recv_queue_avg].to_f,
      :local_recv_queue => status[:wsrep_local_recv_queue].to_i,
      :local_send_queue_avg => status[:wsrep_local_send_queue_avg].to_f,
      :local_send_queue => status[:wsrep_local_send_queue].to_i,
      :cluster_size => status[:wsrep_cluster_size].to_i,
      :primary => (status[:wsrep_cluster_status] == 'Primary' ? 1 : 0),
      :ready => (status[:wsrep_ready] == 'ON' ? 1 : 0),
      :connected => (status[:wsrep_connected] == 'ON' ? 1 : 0)
    )

  end

  def mysql_query(query)
    begin
       result = `#{@mysql_command} -e "#{query}"`
       if $?.success?
         output = {}
         result.split(/\n/).each do |line|
            row = line.split(/\t/)
            output[row.first.to_sym] = row.last
         end
         output
       else
         raise MysqlConnectionError, result
       end
    rescue Exception => e
       raise MysqlConnectionError, e
    end
  end

  class MysqlConnectionError < Exception
  end
end
