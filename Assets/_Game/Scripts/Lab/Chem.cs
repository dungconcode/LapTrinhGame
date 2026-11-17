namespace Underlab.Lab
{
    /// <summary>Hằng số hoá học dùng trong phòng thí nghiệm (đơn vị g/mol).</summary>
    public static class Chem
    {
        public const float H = 1.008f, C = 12.011f, O = 15.999f, Mg = 24.305f, S = 32.06f, Cl = 35.45f, K = 39.098f;
        public const float O2 = O * 2f;
        public const float MgO = Mg + O;
        public const float KCl = K + Cl;
        public const float H2O = H * 2f + O;

        /// <summary>Viết công thức có chỉ số dưới cho TextMeshPro: "O2" => "O<sub>2</sub>".</summary>
        public static string F(string formula)
        {
            var sb = new System.Text.StringBuilder();
            for (int i = 0; i < formula.Length; i++)
            {
                char c = formula[i];
                bool digitAfterLetter = char.IsDigit(c) && i > 0 && (char.IsLetter(formula[i - 1]) || formula[i - 1] == ')');
                sb.Append(digitAfterLetter ? $"<sub>{c}</sub>" : c.ToString());
            }
            return sb.ToString();
        }
    }
}
