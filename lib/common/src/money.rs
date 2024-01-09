use rand::Rng;

#[derive(Debug, Clone, Copy, serde::Serialize, serde::Deserialize)]
pub struct Money {
    value: u64,
}

impl Money {
    pub fn new(value: u64) -> Self {
        Self { value }
    }

    pub fn divide(self, parts: u64) -> Vec<u64> {
        if parts == 0 {
            return Vec::new();
        }

        let base_value = self.value / parts;
        let mut results = vec![base_value; parts as usize];

        let mut remainder = self.value % parts;

        let mut rng = rand::thread_rng();
        let mut index = rng.gen_range(0..parts as usize);

        while remainder > 0 {
            results[index % parts as usize] += 1;
            remainder -= 1;
            index += 1;
        }

        results
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    #[test]
    fn test_divide_evenly() {
        let money = Money::new(30);
        let parts = money.divide(3);
        assert_eq!(parts, vec![10, 10, 10]);
    }

    #[test]
    fn test_divide_with_remainder() {
        let money = Money::new(20);
        let parts = money.divide(3);

        let total: u64 = parts.iter().sum();
        assert_eq!(total, 20);

        let count_6 = parts.iter().filter(|&&x| x == 6).count();
        let count_7 = parts.iter().filter(|&&x| x == 7).count();

        assert_eq!(count_6, 1);
        assert_eq!(count_7, 2);
    }

    #[test]
    fn test_divide_zero_parts() {
        let money = Money::new(20);
        let parts = money.divide(0);
        assert_eq!(parts.len(), 0);
    }

    #[test]
    fn test_divide_single_part() {
        let money = Money::new(20);
        let parts = money.divide(1);
        assert_eq!(parts, vec![20]);
    }

    #[test]
    fn test_divide_huge_number_multiple_parts() {
        let money = Money::new(80200);
        let parts = money.divide(3);

        let total: u64 = parts.iter().sum();
        assert_eq!(total, 80200);

        let count_26733 = parts.iter().filter(|&&x| x == 26733).count();
        let count_26734 = parts.iter().filter(|&&x| x == 26734).count();

        assert_eq!(count_26733, 2);
        assert_eq!(count_26734, 1);
    }

    #[test]
    fn test_divide_order_is_random() {
        let money = Money::new(999998);
        let mut different_results = HashSet::new();

        for _ in 0..1000 {
            let parts = money.divide(13);
            different_results.insert(parts);
        }

        assert!(different_results.len() > 1);
    }
}
