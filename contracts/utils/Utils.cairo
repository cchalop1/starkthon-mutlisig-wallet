func assert_greater_equal_1{range_check_ptr}(a):
    %{
        from starkware.cairo.common.math_utils import assert_integer
        assert_integer(ids.a)
        assert 1 <= ids.a % PRIME < range_check_builtin.bound, f'a = {ids.a} is out of range.'
    %}
    a = [range_check_ptr]
    let range_check_ptr = range_check_ptr + 1
    return ()
end
