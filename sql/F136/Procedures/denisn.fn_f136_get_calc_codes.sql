use RPG_BD

go                 
    if object_id('rpg_develop.fn_f136_get_calc_codes') is not null
    begin
        drop function rpg_develop.fn_f136_get_calc_codes
    end
go

 