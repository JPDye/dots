def main [] {
    niri msg event-stream 
    | lines
    | where { |line| $line | str starts-with "Overview toggled: " }
    | each { |line|
        let state = $line | str replace --all "Overview toggled: " ""
        
        if $state == "true" {
            sleep 0.1sec
            run-external eww open powermenu
        } else if $state == "false" {
            try {
                run-external eww close powermenu
            }
        }
    }
}

main
