namespace Underlab.Lab
{
    /// <summary>Một thí nghiệm trong phòng thí nghiệm (mỗi cái 1 tab).</summary>
    public interface ILabExperiment
    {
        string Title { get; }
        void Tick(float dt);
        /// <summary>Đóng phòng / đổi tab: khoá van, tắt lửa, trả chất trên khay về kho.</summary>
        void OnClose();
    }
}
